get '/offers' do
  @user = User.find(session[:user_id])
  haml :offers
end
