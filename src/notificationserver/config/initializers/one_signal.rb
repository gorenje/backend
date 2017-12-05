require 'one_signal'

OneSignal::OneSignal.tap do |c|
  c.user_auth_key = ENV['ONESIGNAL_USER_AUTH_KEY']
  c.api_key = ENV['ONESIGNAL_API_KEY']
end
