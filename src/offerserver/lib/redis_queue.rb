require 'json'

class RedisQueue
  attr_reader :connection_pool, :key

  def initialize(connection_pool, key)
    @connection_pool = connection_pool
    @key             = key
  end

  def push(elements)
    with_redis do |redis|
      redis.pipelined do |pipe|
        elements.each {|e| pipe.rpush(key, e)}
      end
    end
  end

  def pop(number_of_elements = 20)
    with_redis do |redis|
      redis.pipelined do |pipe|
        number_of_elements.times { pipe.lpop(key) }
      end
    end
  end

  def peek_all
    with_redis { |redis| redis.lrange(key, 0, redis.llen(key)) }
  end

  def size
    with_redis {|redis| redis.llen(key)}
  end

  def clear!
    with_redis {|redis| redis.del(key)}
  end

  protected

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
