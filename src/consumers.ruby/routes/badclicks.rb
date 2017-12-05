get '/badurls' do
  @elements = RedisQueue.new($redis.local, :click_invalid).peek_all
  @keys     = @elements.map { |a| a.keys }.flatten.uniq
  erb :badclicks
end

post '/badurls/clear_all' do
  if params[:confirm] == "yes"
    RedisQueue.new($redis.local, :click_invalid).clear!
  end

  redirect "/badurls"
end
