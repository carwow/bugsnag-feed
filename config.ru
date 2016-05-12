require 'rubygems'
require 'bundler'

Bundler.require

set :cache, Dalli::Client.new

use Rack::Cache,
  metastore:    'file:/tmp/bugsnagfeed/cache/rack/meta',
  entitystore:  'file:/tmp/bugsnagfeed/cache/rack/body',
  verbose:      true

$stdout.sync = true

require './app.rb'
run Sinatra::Application
