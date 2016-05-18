class Project
  extend Forwardable
  def_delegators :@project, :name, :id, :html_url

  def self.all(token:)
    cache = Dalli::Client.new
    client = Bugsnag::Api::Client.new(auth_token: token)
    
    client.projects.map do |project|
      key = "bugsnag-open-errors-#{project.id}"
      number_of_open_errors = cache.get(key)

      if number_of_open_errors.nil?
        number_of_open_errors = client.errors(project.id, {status: 'open'}).count
        cache.set(key, number_of_open_errors, 90)
      end

      self.new(project: project, open_errors_count: open_errors_count)
    end
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
end
