get '/profile/:external_id' do
  @user = User.find_by_external_id(params[:external_id])
  haml :"user/profile_external"
end

get '/profile' do
  @user = User.find(session[:user_id])
  haml :"user/profile"
end

post '/profile' do
  session[:message] = "Successfully Updated"

  User.find(session[:user_id]).update(:name => params[:username])

  redirect '/profile'
end
