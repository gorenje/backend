get '/google/album' do
  haml :"user/google_album"
end

post '/google/album' do
  if params[:file].nil?
    session[:message] = "No image included"
    redirect("/google/album")
  end

  if params[:text].empty?
    halt(413, "Text missing")
  end
  if (params[:link] =~ /@([-?[:digit:]\.]+),([-?[:digit:]\.]+)/).nil?
    halt(413, "Link wrong format")
  end

  lat,lng = [$1,$2].map(&:to_f)
  @user = User.find(session[:user_id])
  NotifierHelper.register(@user)
  offer = generate_subject_from_params(@user)

  offer[:owner] = "GoogleAlbum"
  offer[:extdata] = {
    :link => params[:link]
  }
  offer[:radiusMeters] = 500
  offer[:keywords] = ["#googlealbum", "#all"]
  offer[:location][:coordinates] = [lng,lat]
  session[:message] = "Created Google Album Entry"

  StoreHelper.new_offer(offer)
  redirect("/google/album")
end
