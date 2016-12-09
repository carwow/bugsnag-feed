class Project
  extend Forwardable

  PROJECT_BATCHES =
    [
      [ {:id=>:'583844d7e694aa43f173743b', :name=> 'Kafka to Redshift',              url: 'https://app.bugsnag.com/carwow/kafka-to-redshift'},
        {:id=>:'5833120be694aa2dd16b3b0f', :name=> 'Other',                          url: 'https://app.bugsnag.com/carwow/other-4'},
        {:id=>:'582f2210e694aa31ba76b6c3', :name=> 'Push Notifications Service UK',  url: 'https://app.bugsnag.com/carwow/push-notifications-service-uk'},
        {:id=>:'582dc4e7bbddbd2f43e36066', :name=> 'Finance Calculator API',         url: 'https://app.bugsnag.com/carwow/finance-calculator-api'}
      ],
      [ {:id=>:'5829c488e694aa02d5d83d27', :name=> 'Izmo Photos Elixir',             url: 'https://app.bugsnag.com/carwow/izmo-photos-elixir'},
        {:id=>:'57ff89d8bbddbd7551186662', :name=> 'Price Scraper',                  url: 'https://app.bugsnag.com/carwow/price-scraper'},
        {:id=>:'57f4e0ade694aa6a8005749c', :name=> 'BusinessEventUnpacker UK',       url: 'https://app.bugsnag.com/carwow/businesseventunpacker-uk'},
        {:id=>:'57ebe7e3e694aa5fc5835d6f', :name=> 'Heroku to redshift DE',          url: 'https://app.bugsnag.com/carwow/heroku-to-redshift-de'}
      ],
      [ {:id=>:'57ebe7c5e694aa5f24c27165', :name=> 'Heroku to redshift UK',          url: 'https://app.bugsnag.com/carwow/heroku-to-redshift-uk'},
        {:id=>:'57d6bb82e694aa205fb38ad2', :name=> 'Bi App',                         url: 'https://app.bugsnag.com/carwow/bi-app'},
        {:id=>:'573200137765627287000250', :name=> 'Jato Importer',                  url: 'https://app.bugsnag.com/carwow/jato-importer'},
        {:id=>:'571f20b777656205cf00010b', :name=> 'Performance Stats Service - DE', url: 'https://app.bugsnag.com/carwow/performance-stats-service-germany'}
      ],
      [ {:id=>:'571e2bbd7765621443000091', :name=> 'Admin Site - DE',                url: 'https://app.bugsnag.com/carwow/admin-site-germany'},
        {:id=>:'5714f3d37765626cd40000d5', :name=> 'Dealers Site - DE',              url: 'https://app.bugsnag.com/carwow/dealers-site-germany'},
        {:id=>:'56dac5977765622b830001fa', :name=> 'Research Site – DE',             url: 'https://app.bugsnag.com/carwow/research-site-germany'},
        {:id=>:'56dac2f77765621ee900067f', :name=> 'Quotes Site – DE',               url: 'https://app.bugsnag.com/carwow/quotes-site-germany'}
      ],
      [ {:id=>:'56d825807765621e4d00019f', :name=> 'Performance Stats Service',      url: 'https://app.bugsnag.com/carwow/performance-stats-service'},
        {:id=>:'5658852077656232eb0002bd', :name=> 'Datasnaps',                      url: 'https://app.bugsnag.com/carwow/datasnaps'},
        {:id=>:'564f28ee7765626418000029', :name=> 'Izmo Photo Importer',            url: 'https://app.bugsnag.com/carwow/izmo-photo-importer'},
        {:id=>:'55099e2977656258ac002cc5', :name=> 'Dealers Site',                   url: 'https://app.bugsnag.com/carwow/dealers-site'}
      ],
      [ {:id=>:'5472ff7f7765627446010b23', :name=> 'Caps Importer',                  url: 'https://app.bugsnag.com/carwow/caps-importer'},
        {:id=>:'546e1d1a7765625929004748', :name=> 'Research Site',                  url: 'https://app.bugsnag.com/carwow/research-site'},
        {:id=>:'546df4157765627675006058', :name=> 'Quotes Site',                    url: 'https://app.bugsnag.com/carwow/quotes-site'},
        {:id=>:'546ca5d4776562085600085d', :name=> 'Admin Site',                     url: 'https://app.bugsnag.com/carwow/admin-site'}
      ]
    ]

  def initialize(project:, open_errors_count:)
    @name = project[:name],
    @url = project[:url],
    @open_errors_count = open_errors_count
  end

  def self.all(token:)
    projects = get_all_projects_from_cache

    update_projects(projects, token) if should_update_projects?
  end

  def self.update_projects(projects, token)
    client = Bugsnag::Api::Client.new(auth_token: token)

    next_batch_to_run = self.next_batch_to_run
    projects_to_update = PROJECT_BATCHES[next_batch_to_run]
    projects_to_update.each do |project|
      begin
        open_errors_count = self.fetch(cache_key(project)) do
          client.errors(project_id, {status: 'open'}).count
        end

        projects[project[:id]] = self.new(project: project, open_errors_count: open_errors_count)

      rescue Bugsnag::Api::ClientError => e
        $stdout.puts "Can't retrieve errors for project #{project.name}, probably due to API rate limit"
      end
    end
    cache = Dalli::Client.new
    cache.set('last_batch_run', {index: next_batch_to_run, time: Time.now})

    projects
  end

  def self.get_all_projects_from_cache
    cache = Dalli::Client.new
    PROJECT_BATCHES.flatten.reduce({}) do |result, project|
      result[project[:id]] = self.new(project: project, open_errors_count: cache.get(cache_key(project)))
      result
    end
  end

  def status
    (@open_errors_count > 0) ? 'Error' : 'Success'
  end

  def self.fetch(key, expires_in: nil)
    if ENV['DISABLE_CACHING']
      return yield
    end

    cache = Dalli::Client.new
    value = cache.get(key)
    if value.nil?
      value = yield
      cache.set(key, value, expires_in)
    end
    value
  end

  def self.cache_key(project)
    "bugsnag-open-errors-#{project[:id]}"
  end

  def self.should_update_projects?
    (Time.now - last_batch_run[:time]) > 30
  end

  def self.last_batch_run
    self.fetch('last_batch_run', expires_in: nil) do
      one_hour_ago = Time.now - 3600
      {index: PROJECT_BATCHES.size-1, time: one_hour_ago}
    end
  end

  def self.next_batch_to_run
    last_batch_run[:index]+1 % PROJECT_BATCHES.size
  end

end