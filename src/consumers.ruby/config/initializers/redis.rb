require 'redis'
require 'redis/connection/hiredis'

require 'connection_pool'

$redis = OpenStruct.new.tap do |os|
  { "local"       => 'REDISTOGO_URL',
  }.each do |name, env_name|
    os[name] = ConnectionPool.
      new(:size => (ENV["REDIS_POOL_SIZE_#{env_name}"] ||
                    ENV['REDIS_POOL_SIZE'] || '5').to_i) do
      Redis.new(:url => ENV[env_name], :driver => :hiredis)
    end
  end
end
