class Mapping < ActiveRecord::Base

  def fire_push(notification)
    notifyobj = notification.localize(self)

    unless callback_url.blank?
      RestClient.post(callback_url, JSON(notifyobj.to_json)) rescue nil
    end

    unless onesignal_id.blank?
      OneSignalHelper.send_message_to_player(onesignal_id,notifyobj)
    end
  end
end
