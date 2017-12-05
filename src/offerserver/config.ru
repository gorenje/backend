require_relative 'application'

use Rack::Session::Cookie, :secret => ENV["COOKIE_SECRET"]
use AuthFilter

use OmniAuth::Builder do
  provider(:google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           :verify_iss => false)
end

run Rack::URLMap.new(
  "/"        => Sinatra::Application.new,
  "/sidekiq" => SidekiqWebNoSessions
)
