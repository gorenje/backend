before '/api/:version/:action' do
  if ENV['API_SECRET_KEY']
    pepper = Digest::SHA1.
      hexdigest(request.env["HTTP_X_API_SALT"] + params[:postback] +
                ENV['API_SECRET_KEY']) rescue "#{params[:pepper]}dontmatch"
    halt(404) if params[:pepper] != pepper
  end
end

post '/api/:version/create' do
  cl = JSON.parse(params[:postback])
  Postback.
    find_or_create_by(:id => cl["id"]).
    update(cl)
  json({ :status => :ok })
end

post '/api/:version/delete' do
  cl = JSON.parse(params[:postback])
  Postback.find(cl["id"]).delete rescue nil
  json({ :status => :ok })
end
