module CacheResponse
  def cache(key:, default: [], expires_in: 127)
    response = nil

    puts "[Cache] #{key} Lookup"
    settings.cache.fetch(key) do
      begin
        puts "[Api] #{key} Data fetch"
        response = yield
      rescue
        puts "[Api] #{key} Error"
        return default
      end

      puts "[Cache] #{key} Persisting.."
      settings.cache.set(key, response, expires_in)
      puts "[Cache] #{key} Persisted.."
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
    errors = Errors.by_project(self)
    return nil if errors.nil?

    status = 'Success'
    status = 'Error' if errors.any?
    status
  end

  private
  def self.all_projects(token:, client:)
    cache(key: "#{token}:all_projects", expires_in: 300) do
      client.projects
    end
  end
end

class Errors
  extend CacheResponse

  def self.by_project(project)
    cache(key: "#{project.id}:open_errors", default: nil) do
      project.client.errors(project.id, per_page: 1, status: 'open')
    end
  end
end
