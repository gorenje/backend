module RedisHelper
  extend self

  def rate_limit_offer(offr, srch, &block)
    yield_if_key_unset(offer_key(srch, offr), &block)
  end

  def rate_limit_search(srch, offr, &block)
    yield_if_key_unset(search_key(srch, offr), &block)
  end

  def search_key(srch, offr)
    "search.#{srch.id}.#{offr.id}"
  end

  def offer_key(srch, offr)
    "offer.#{offr.id}.#{srch.id}"
  end

  def yield_if_key_unset(key, &block)
    with_redis do |redis|
      yield if redis.ttl(key) == -2
      redis.setex(key, ENV['RATE_LIMIT_SECONDS'], "sent")
    end
  end

  protected

  def with_redis
    $redis_pool.with do |redis|
      yield redis
    end
  end
end
