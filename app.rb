get '/projects' do
  cache_control :public, max_age: 60
  content_type 'text/html'
  auth_token = params[:auth_token]
  client = Bugsnag::Api::Client.new(auth_token: auth_token)

  html = "<html><body>"
  html << "<dl>"
  client.projects.each do |project|
    project_url = url("/projects/#{project.id}?auth_token=#{auth_token}")
    html << "<dt>#{project.name}</dt><dd><a href='#{project_url}'>#{project_url}</a></dd>"
    { name: project.name, id: project.id}
  end
  html << "</dl>"
  html << "</body></html>"
end

get '/projects/:project_id' do
  cache_control :public, max_age: 120
  content_type 'text/xml'
  auth_token = params[:auth_token]
  client = Bugsnag::Api::Client.new(auth_token: auth_token)

  project = client.project(params[:project_id])
  errors = client.errors(params[:project_id], per_page: 1, status: 'open')

  project_name = "bugsnag - #{project.name}"

  status = 'Success'
  status = 'Error' if errors.any?

  %Q{<?xml version="1.0" encoding="UTF-8"?>
      <Projects>
        <Project lastBuildStatus="#{status}" name="#{project_name}" activity="Sleeping" webUrl="#{project.html_url}">
        </Project>
      </Projects>}
end
