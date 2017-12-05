require 'rubygems'
require 'bundler'
require 'bundler/setup'

require_relative 'app'

use(Rack::Session::Cookie,
            :path         => "/",
            :secret       => ENV['COOKIE_SECRET'],
            :expire_after => 86400)

run Rack::URLMap.new(
  "/" => Sinatra::Application.new,
)
