require_relative 'application'

use Rack::Session::Cookie, :secret => ENV["COOKIE_SECRET"]
use AuthFilter

run Rack::URLMap.new(
  "/"        => Sinatra::Application.new,
  "/sidekiq" => SidekiqWebNoSessions
)
