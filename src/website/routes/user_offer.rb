get '/offer/create' do
  @search_raw = {:text => ""}
  @search     = OpenStruct.new(@search_raw)
  @user       = User.find(session[:user_id])
  haml :create_offer
end

get '/offer/:objid/create' do
  @search_raw = StoreHelper.object(params[:objid])
  @search     = OpenStruct.new(@search_raw)
  @user       = User.find(session[:user_id])
  haml :create_offer
end

get '/offer/:id/edit' do
  @offer_raw  = StoreHelper.object(params[:id])
  @offer      = OpenStruct.new(@offer_raw)
  @user       = User.find(session[:user_id])

  if (@user.userid_for_sendbird == @offer.owner)
    haml :update_offer
  else
    redirect "/user/offers"
  end
end

post '/offer/create_advanced' do
  @user = User.find(session[:user_id])
  NotifierHelper.register(@user)
  StoreHelper.new_offer(generate_subject_from_params(@user))
  redirect "/user/offers"
end

post '/offer/:id/update' do
  if_user_is_owner(params[:id]) do |user|
    NotifierHelper.register(user)
    StoreHelper.update_offer(params[:id], generate_subject_from_params(user))
  end
  redirect "/user/offers"
end
