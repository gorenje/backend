get '/badclicks' do
  @elements = RedisQueue.new($redis_pool, :click_invalid).peek_all
  @keys     = @elements.map { |a| a.keys }.flatten.uniq
  erb :badclicks
end

post '/badclicks/clear_all' do
  if params[:confirm] == "yes"
    RedisQueue.new($redis_pool, :click_invalid).clear!
  end

  redirect "/badclicks"
end
