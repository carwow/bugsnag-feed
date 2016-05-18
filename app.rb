require_relative 'projects.rb'

get '/projects' do
  cache_control :public, max_age: 60
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
