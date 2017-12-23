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

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and
      @auth.credentials == [ENV['API_USER'] || 'assets',
                            ENV['API_PASSWORD'] || 'asserts']
  end
end
