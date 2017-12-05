require 'redis'
require 'redis/connection/hiredis'

require 'connection_pool'

redis_conn = proc {
  Redis.new(:url => ENV['REDISTOGO_URL'], :driver => :hiredis)
}

$redis_pool =
  ConnectionPool.new(:size => (ENV['REDIS_POOL_SIZE'] || '5').to_i, &redis_conn)
