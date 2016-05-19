class Project
  extend Forwardable
  def_delegators :@project, :name, :id, :html_url

  def self.all(token:)
    client = Bugsnag::Api::Client.new(auth_token: token)

    project_key = 'bugsnag-projects'
    projects = self.fetch(project_key, expires_in: 300) do
      client.projects
    end
    
    projects.map do |project|
      begin
      key = "bugsnag-open-errors-#{project.id}"

      open_errors_count = self.fetch(key) do
        client.errors(project.id, {status: 'open'}).count
      end

      self.new(project: project, 
               open_errors_count: open_errors_count)

      rescue Bugsnag::Api::ClientError => e
        $stdout.puts "Can't retrieve errors for project #{project.name}, probably due to API rate limit"
      end
    end.compact
  end

  def initialize(project:, open_errors_count:)
    @project = project
    @open_errors_count = open_errors_count
  end

  def status
    status = 'Success'
    status = 'Error' if @open_errors_count > 0
    status
  end

  def self.fetch(key, expires_in: 90)
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
end
