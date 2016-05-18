class Project
  extend Forwardable
  def_delegators :@project, :name, :id, :html_url

  def self.all(token:)
    client = Bugsnag::Api::Client.new(auth_token: token)
    
    client.projects.map do |project|
      self.new(project: project)
    end
  end

  def initialize(project:)
    @project = project
  end

  def status
    errors = @project.errors
    return nil if errors.nil?

    status = 'Success'
    status = 'Error' if errors > 0
    status
  end
end
