get '/api/startchat' do
  return_json do
    user          = User.find(session[:user_id])
    sendbird_user = user.userid_for_sendbird

    if params[:channel_url]
      {
        :status     => :ok,
        :nickname   => user.name,
        :userid     => sendbird_user,
        :channelUrl => params[:channel_url]
      }
    elsif subject = StoreHelper.object(params[:objid])
      owner = subject["owner"]

      NotifierHelper.register(user)

      data = {
        :user_ids    => [owner, sendbird_user],
        :is_distinct => false,
        :name        => "#{subject['_id']}_596916c4d028210004ba61d0",
        :data        => "subjectid:#{subject['_id']}"
      }

      groupchat   = SendbirdApi.new.group_channels.post(data)
      channel_url = groupchat["channel"]["channel_url"]

      {
        :status     => :ok,
        :nickname   => user.name,
        :userid     => sendbird_user,
        :channelUrl => channel_url
      }
    else
      {
        :status => :error,
        :msg    => I18n.t("errors.object_no_longer_exists")
      }
    end
  end
end
