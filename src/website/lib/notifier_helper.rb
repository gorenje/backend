module NotifierHelper
  extend self

  def register(user)
    RestClient.post($hosthandler.notifier.url + "/register", {
                      :device_id    => user.sendbird_userid,
                      :sendbird_id  => user.sendbird_userid,
                      :callback_url => user.notification_callback_url
                    }) rescue nil
  end
end
