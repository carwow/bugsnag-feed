set :cache, Dalli::Client.new

module CacheResponse
  def cache(key:, default: [], duration: 60)
    response = nil
    settings.cache.fetch(key) do
      begin
        response = yield
      rescue
        return default
      end

      settings.cache.set(key, response, 300)
      response
    end
  end
end

class Project
  extend Forwardable
  extend CacheResponse
  def_delegators :@project, :name, :id, :html_url
  attr_reader :client

  def self.all(token:)
    client = Bugsnag::Api::Client.new(auth_token: token)

    all_projects(token: token, client: client).map do |project|
      self.new(project: project, client: client)
    end
  end

  def self.find(id, token:)
    self.all(token: token).find { |p| p.id == id }
  end

  def initialize(project:, client:)
    @client = client
    @project = project
  end

  def status
    status = 'Success'
    status = 'Error' if Errors.by_project(self).any?
    status
  end

  private
  def self.all_projects(token:, client:)
    cache(key: "#{token}:all_projects", duration: 300) do
      projects = client.projects
      return projects
    end
  end
end

class Errors
  extend CacheResponse

  def self.by_project(project)
    cache(key: "#{project}:open_errors") do
      errors = project.client.errors(project.id, per_page: 1, status: 'open')
      return errors
    end
  end
end
