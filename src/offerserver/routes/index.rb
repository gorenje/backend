get '/' do
  redirect '/sidekiq'
end

get "/pingdom" do
  $redis_pool.with do |redis|
    redis.ping
  end
  erb "ok"
end
