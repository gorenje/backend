require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/contrib'
require 'oauth2'
require 'json'
require 'action_view'
require 'haml'

ENV['environment'] = ENV['RACK_ENV'] || 'development'

set :logging, true
set :static, true

require_relative 'lib/view_helpers'

helpers do
  include ImageServer::ViewHelpers
end

require_relative 'config/initializers/carrierwave'
require_relative 'config/initializers/database'

Dir[File.join(File.dirname(__FILE__),'routes','*.rb')].each { |a| require a }

get '/' do
  ""
end
