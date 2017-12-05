get '/api/user/offer/:objid/match' do
  return_json do
    if_user_is_owner(params[:objid]) do
      StoreHelper::Agent.new.offers.send(params[:objid]).notify.get
    end
    { :status => :ok }
  end
end

get '/api/user/offer/:objid/create' do
  @search = OpenStruct.new(StoreHelper.object(params[:objid]))
  @i18n   = TranslatorHelper.new("pages.create_offer_for_search")

  return_json do
    {
      :title => @i18n.title.t,
      :form  => haml(:"_create_offer_for_search", :layout => false)
    }
  end
end

get '/api/user/offer/:objid/set_active/:value' do
  return_json do
    @user            = User.find(session[:user_id])
    owner            = @user.userid_for_sendbird
    new_active_value = params[:value] == "true"
    return_value     = { :status => :ok }

    obj = StoreHelper.object(params[:objid])

    if obj["owner"] == owner
      StoreHelper.set_active_offer(params[:objid], new_active_value)
      subject = OpenStruct.new(obj)
      subject.isActive = new_active_value
      NotifierHelper.register(@user)

      if params[:fromlisting]
        i18n = TranslatorHelper.
          new("partials.user_offer_obj_resultslist").button.c

        subject.ranking_num = params[:fromlisting]
        subject.i18n = i18n

        return_value.
          merge(:html => haml(:"_active_button_in_listing", :layout => false,
                              :locals => { :obj => subject }))

      else
        i18n = TranslatorHelper.new("pages.update_offer").button.c

        return_value.
          merge(:html => haml(:"_active_button", :layout => false,
                              :locals => {:subject => subject, :i18n => i18n}))
      end
    else
      return_value
    end
  end
end

get '/api/user/offer/:objid/delete' do
  return_json do
    if_user_is_owner(params[:objid]) do |user|
      StoreHelper.delete_offer(params[:objid])
      NotifierHelper.register(user)
    end
    { :status => :ok }
  end
end

get '/api/user/offers.json' do
  @user = User.find(session[:user_id])
  owner = @user.userid_for_sendbird

  cnt = 0
  return_json do
    StoreHelper.
      user_offers(params[:sw], params[:ne], owner,
                  (params[:keywords]||"").downcase.split(/[[:space:]]+/)).
      map do |hsh|
      hsh.tap do |h|
        fill_hash(h, cnt+=1)
        hsh["i18n"] =
          TranslatorHelper.new("partials.user_offer_obj_resultslist")
        h["resultslist_html"] =
          haml(:"_subject_resultslist_entry", :layout => false, :locals => hsh)
      end
    end.sort_by { |a| a["ranking_num"] }
  end
end

post '/offer/:srchid/create' do
  return_json do
    @user = User.find(session[:user_id])
    owner = @user.userid_for_sendbird

    search = StoreHelper.object(params[:srchid])

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
      :location      => search["location"]
    }

    StoreHelper.new_offer(data)
    NotifierHelper.register(@user)
    { :status => :ok}
  end
end
