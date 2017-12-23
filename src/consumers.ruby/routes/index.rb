get '/' do
  erb ''
end

get "/pingdom" do
  ## TODO extend this to test all redis databases
  $redis.local.with do |redis|
    redis.ping
  end
  erb "ok"
end
