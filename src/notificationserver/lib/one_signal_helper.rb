module OneSignalHelper
  extend self

  def all_players
    JSON(OneSignal::Player.
         all(:params => {:app_id => ENV['ONESIGNAL_APP_ID']}).body)
  end

  def all_applications
    JSON(OneSignal::App.all.body)
  end

  def send_message_to_player(player_id, notification)
    params = {
      "headings"           => ({"en" => notification.title || "No Title"}.
                               merge(notification.locale =>
                                     notification.title || "No Title")),
      "contents"           => ({"en" => notification.msg }.
                               merge(notification.locale =>
                                     notification.msg)),
      "content_available"     => true,
      "include_player_ids"    => [player_id],
      "app_id"                => ENV['ONESIGNAL_APP_ID'],
      "url"                   => notification.url,
      "android_group"         => "push",
      "android_group_message" => {
        "en" => "You have $[notif_count] new messages"
      },
      "ios_badgeType" => "Increase",
      "ios_badgeCount" => 1,
      "data" => notification.data.merge({
        "sent_at" => Time.now.utc.strftime("%s%L").to_i
      })
    }
    JSON( OneSignal::Notification.create(:params => params).body )
  end
end
