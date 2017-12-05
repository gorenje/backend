get '/auth' do
  redirect '/auth/google_oauth2'
end

get '/auth/:provider/callback' do
  @email = request.env['omniauth.auth']["info"]["email"]
  if ENV['ACCESS_DOMAINS'].split(/,/).any? { |a| @email =~ /@#{a}$/ } ||
      (ENV["ACCESS_EMAILS"] || "").split(",").include?(@email)
    session[:authenticated] = true
    session[:user] = {
      :user => request.env['omniauth.auth']["info"],
      :uid  => request.env['omniauth.auth']["uid"],
    }
    redirect session[:lgkp] || '/'
  else
    session[:authenticated] = false
    redirect '/'
  end
end

get '/auth/failure' do
  session[:authenticated] = false
  erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
end

get '/auth/logout' do
  session[:authenticated] = false
  redirect '/'
end
