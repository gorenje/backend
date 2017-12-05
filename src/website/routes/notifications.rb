get '/notifications/:notid/toggleread' do
  return_json do
    user = User.find(session[:user_id])
    notif = user.notifications.where(:id => params[:notid]).first

    if notif
      notif.unread? ? notif.mark_as_read : notif.mark_as_unread

      { :status    => :ok,
        :html      => haml(:"_notification_row", :layout => false,
                           :locals => { :notification => notif}),
        :css_class => notif.unread? ? "unread" : "read"
      }
    else
      { :status => :hide }
    end
  end
end

get '/notifications/:notid/delete' do
  return_json do
    user = User.find(session[:user_id])
    user.notifications.where(:id => params[:notid]).first.try(:destroy)
    { :status => :ok }
  end
end

post '/notification/:external_id' do
  return_json do
    payload = JSON(params.to_json).tap do |p|
      p.delete("captures")
      p.delete("external_id")
    end

    Notification.
      create(:user    => User.find_by_external_id(params[:external_id]),
             :payload => payload)

    { :status => "ok"}
  end
end
