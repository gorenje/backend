get '/search/create' do
  @offer_raw = {:text => ""}
  @offer     = OpenStruct.new(@offer_raw)
  @user      = User.find(session[:user_id])
  haml :create_search
end

get '/search/:objid/create' do
  @offer_raw = StoreHelper.object(params[:objid])
  @offer     = OpenStruct.new(@offer_raw)
  @user      = User.find(session[:user_id])
  haml :create_search
end

get '/search/:id/edit' do
  @search_raw = StoreHelper.object(params[:id])
  @search     = OpenStruct.new(@search_raw)
  @user       = User.find(session[:user_id])

  if (@user.userid_for_sendbird == @search.owner)
    haml :update_search
  else
    redirect "/user/searches"
  end
end

post '/search/create_advanced' do
  @user = User.find(session[:user_id])
  NotifierHelper.register(@user)
  StoreHelper.new_search(generate_subject_from_params(@user))
  redirect "/user/searches"
end

post '/search/:id/update' do
  if_user_is_owner(params[:id]) do |user|
    NotifierHelper.register(user)
    StoreHelper.update_search(params[:id], generate_subject_from_params(user))
  end
  redirect "/user/searches"
end
