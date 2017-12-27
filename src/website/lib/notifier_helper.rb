module NotifierHelper
  extend self

  def _base_url
    host = $hosthandler.notifier
    user, pass = ["USER","PASSWORD"].map { |a| ENV["NOTIFIER_API_#{a}"] }
    "#{host.protocol}://#{user}:#{pass}@#{host.host}/"
  end

  def register(user)
    RestClient.post(_base_url + "register", {
                      :device_id    => user.sendbird_userid,
                      :sendbird_id  => user.sendbird_userid,
                      :callback_url => user.notification_callback_url
                    }) rescue nil
  end
end
