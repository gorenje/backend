post /\/sendbird\/.*/ do
  params = get_json_params

  return_json do
    halt(404) if params["app_id"] != ENV['SENDBIRD_APP_ID']

    case params["category"]
    when "group_channel:message_send"
      sender       = (params["sender"] ||  {})["user_id"]
      recipients   = ((params["members"] || []).map { |u| u["user_id"] } -
                      [sender])

      notification = PushHelper.
        open_chat((params["channel"] || {})["name"],
                  (params["channel"] || {})["channel_url"],
                  (params["payload"] || {})["message"])

      recipients.
        map { |r| Mapping.where(:sendbird_id => r) }.
        flatten.
        compact.
        map { |m| m.fire_push(notification) }

      TrackerHelper.chat_message(params)
    end

    puts params
    puts request.path_info

    { :status => :ok}
  end
end
