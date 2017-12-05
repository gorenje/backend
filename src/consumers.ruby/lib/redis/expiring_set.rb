class RedisExpiringSet

  attr_reader :connection_pool

  def initialize(connection_pool)
    @connection_pool = connection_pool
    @cache = new_hash_cache
  end

  def add_click_event(event)
    @cache[event.lookup_key][event.payload] = event.max_age
#    expire!(event.lookup_key)
    flush if cache_full?
  end

  def flush
    max_ttls = {}
    now_time = Time.now.to_i

    with_redis do |redis|
      redis.pipelined do |pipe|
        @cache.keys.each do |key|
          max_ttls[key] = []
          @cache[key].keys.each do |payload|
            time = @cache[key][payload].to_i
            max_ttls[key] << (time - now_time)
            pipe.zadd key, time, payload
          end
        end
      end

      max_ttls.keys.each do |key|
        m = max_ttls[key].max
        redis.expire(key, m) if redis.ttl(key) < m
      end
    end
    @cache = new_hash_cache
  end

  def expire!(key, time = Time.now)
    with_redis do |redis|
      redis.pipelined do |pipe|
        pipe.zremrangebyscore key, 0, time.to_i
      end
    end
  end

  def remove_value_from_key(key, value)
    with_redis do |redis|
      redis.zrem key, value
    end
  end

  def find_by_lookup_keys(keys, start_time, end_time)
    with_redis do |redis|
      Hash[keys.zip(redis.pipelined do |pipe|
                      keys.each do |key|
                        pipe.zrangebyscore(key, start_time.to_i,
                                           end_time.to_i) || []
                      end
                    end)].reject { |_,v| v.empty? }
    end
  end

  protected

  def cache_full?
    @cache.keys.size > 400 ||
      (@cache.keys.map{ |k| @cache[k].keys.size }).sum > 400
  end

  def new_hash_cache
    Hash.new { |h,k| h[k] = Hash.new(0) }
  end

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
