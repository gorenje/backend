class RedisClickStats
  attr_reader :connection_pool

  def initialize(connection_pool)
    @connection_pool = connection_pool
    @pipe_commands   = []
    @stats           = new_stats_hash
  end

  def update_postback(pbstats_event)
    key = "pbstats:pb:#{pbstats_event.postback_id}"

    @stats[key]["count"] += 1
    @stats[key]["respcode:#{pbstats_event.response_code}"] += 1

    flush if @stats.keys.size > 20
  end

  def update(click_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    @stats[key]["count"] += 1
    @stats[key]["country:#{click_event.country}"]    += 1
    @stats[key]["platform:#{click_event.platform}"]  += 1
    @stats[key]["device:#{click_event.device_name}"] += 1
    @stats[key]["device_type:#{click_event.device}"] += 1

    (@stats[key]["botclick"] += 1) if click_event.is_bot?
    (@stats[key]["with_adid"] += 1) if click_event.has_adid?

    flush if @stats.keys.size > 20
  end

  def conversion(click_event, install_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    @stats[key]["conversion"] += 1
    @stats[key]["conversion:country:#{install_event.country}"] +=1

    flush if @stats.keys.size > 20
  end

  def flush
    with_redis do |redis|
      redis.pipelined do |pipe|
        @stats.keys.each do |key|
          @stats[key].keys.each do |attribute|
            pipe.zincrby(key, @stats[key][attribute], attribute)
          end
        end
      end
    end
    @stats = new_stats_hash
  end

  protected

  def new_stats_hash
    Hash.new { |h,k| h[k] = Hash.new(0) }
  end

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
