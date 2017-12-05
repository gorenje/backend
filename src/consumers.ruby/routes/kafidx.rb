get '/kafidx/getgroupid' do
  hex = Digest::MD5.hexdigest(request.ip)[0..5]
  session[:kafka_group_id] = "kafidx-#{hex}-#{(rand * 1000).to_i}"
  redirect back
end

get '/kafidx' do
  if session[:kafka_group_id]
    @ws_scheme = ENV['RACK_ENV'] == "production" ? "wss" : "ws"
    haml :kafidx
  else
    redirect '/kafidx/getgroupid'
  end
end

get '/matches' do
  @ws_scheme = ENV['RACK_ENV'] == "production" ? "wss" : "ws"
  haml :matches
end
