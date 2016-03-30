require 'rubygems'
require 'bundler'

Bundler.require

use Rack::Cache,
  metastore:    'file:/tmp/bugsnagfeed/cache/rack/meta',
  entitystore:  'file:/tmp/bugsnagfeed/cache/rack/body',
  verbose:      true

require './app.rb'
run Sinatra::Application
