require_relative 'projects.rb'

get '/projects/:project_id' do
  cache_control :public, max_age: 90
  content_type 'text/xml'
  auth_token = params[:auth_token]

  project = Project.find(params[:project_id], token: auth_token)
  return status 500 if project.nil? || project.status.nil?

  %Q{<?xml version="1.0" encoding="UTF-8"?>
      <Projects>
        <Project lastBuildStatus="#{project.status}" name="bugsnag - #{project.name}" activity="Sleeping" webUrl="#{project.html_url}">
        </Project>
      </Projects>}
end

get '/projects' do
  cache_control :public, max_age: 90
  content_type 'text/xml'
  auth_token = params[:auth_token]

  result = '<?xml version="1.0" encoding="UTF-8"?>'
  result << '<Projects>'
  Project.all(token: auth_token).each do |project|
    result << %Q{<Project lastBuildStatus="#{project.status}" name="bugsnag - #{project.name}" activity="Sleeping" webUrl="#{project.html_url}"></Project>}
  end
  result << '</Projects>'
  result
end
