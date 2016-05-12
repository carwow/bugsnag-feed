require_relative 'projects.rb'

get '/projects' do
  cache_control :public, max_age: 60
  content_type 'text/html'
  auth_token = params[:auth_token]

  html = "<html><body>"
  html << "<dl>"
  Project.all(token: auth_token).each do |project|
    project_url = url("/projects/#{project.id}?auth_token=#{auth_token}")
    html << "<dt>#{project.name}</dt><dd><a href='#{project_url}'>#{project_url}</a></dd>"
    { name: project.name, id: project.id}
  end
  html << "</dl>"
  html << "</body></html>"
end

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
