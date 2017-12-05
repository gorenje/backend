get '/api/user/search/:objid/match' do
  return_json do
    if_user_is_owner(params[:objid]) do
      StoreHelper::Agent.new.searches.send(params[:objid]).notify.get
    end
  end
end

get '/api/user/search/:objid/create' do
  @offer = OpenStruct.new(StoreHelper.object(params[:objid]))
  @i18n  = TranslatorHelper.new("pages.create_search_for_offer")

  return_json do
    {
      :title => @i18n.title.t,
      :form  => haml(:"_create_search_for_offer", :layout => false)
    }
  end
end

get '/api/user/search/:objid/set_active/:value' do
  return_json do
    @user            = User.find(session[:user_id])
    owner            = @user.userid_for_sendbird
    new_active_value = params[:value] == "true"
    return_value     = { :status => :ok }

    obj = StoreHelper.object(params[:objid])

    if obj["owner"] == owner
      StoreHelper.set_active_search(params[:objid], new_active_value)
      subject = OpenStruct.new(obj)
      subject.isActive = new_active_value
      NotifierHelper.register(@user)

      if params[:fromlisting]
        i18n = TranslatorHelper.
          new("partials.user_search_obj_resultslist").button.c

        subject.ranking_num = params[:fromlisting]
        subject.i18n = i18n

        return_value.
          merge(:html => haml(:"_active_button_in_listing", :layout => false,
                              :locals => { :obj => subject }))
      else
        i18n = TranslatorHelper.new("pages.update_search").button.c

        return_value.
          merge(:html => haml(:"_active_button", :layout => false,
                              :locals => {:subject => subject, :i18n => i18n}))
      end
    else
      return_value
    end
  end
end

get '/api/user/search/:objid/delete' do
  return_json do
    if_user_is_owner(params[:objid]) do |user|
      StoreHelper.delete_search(params[:objid])
      NotifierHelper.register(user)
    end

    { :status => :ok }
  end
end

get '/api/user/searches.json' do
  @user = User.find(session[:user_id])
  owner = @user.userid_for_sendbird

  cnt = 0
  return_json do
    StoreHelper.
      user_searches(params[:sw], params[:ne], owner,
                    (params[:keywords]||"").downcase.split(/[[:space:]]+/)).
      map do |hsh|
      hsh.tap do |h|
        fill_hash(h, cnt+=1)
        hsh["i18n"] =
          TranslatorHelper.new("partials.user_search_obj_resultslist")
        h["resultslist_html"] =
          haml(:"_subject_resultslist_entry", :layout => false, :locals => hsh)
      end
    end.sort_by { |a| a["ranking_num"] }
  end
end

post '/search/:offerid/create' do
  return_json do
    @user = User.find(session[:user_id])
    owner = @user.userid_for_sendbird

    offer = StoreHelper.object(params[:offerid])

    data = {
      :owner         => owner,
      :text          => params[:text],
      :keywords      => params[:text].downcase.split(/[[:space:]]+/),
      :validfrom     => Time.now.utc.strftime("%s%L").to_i,
      :validuntil    => (Date.today + 1000).to_time.utc.strftime("%s%L").to_i,
      :isMobile      => false,
      :allowContacts => true,
      :showLocation  => true,
      :extdata       => {},
      :location      => offer["location"]
    }

    StoreHelper.new_search(data)
    NotifierHelper.register(@user)
    {:status => :ok}
  end
end
