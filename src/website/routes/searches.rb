get '/searches' do
  @user = User.find(session[:user_id])
  haml :searches
end
