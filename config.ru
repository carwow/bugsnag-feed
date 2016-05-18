require 'rubygems'
require 'bundler'

Bundler.require

dalli_client = Dalli::Client.new

use Rack::Cache,
  metastore:    dalli_client,
  entitystore:  dalli_client,
  verbose:      true

$stdout.sync = true

require './app.rb'
run Sinatra::Application
