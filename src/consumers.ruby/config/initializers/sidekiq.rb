require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

require_relative 'redis'

cron_jobs = [
             {
               'name'  => 'geo_worker_scheduler',
               'class' => 'Scheduler::Geo',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'chatbot_worker_scheduler',
               'class' => 'Scheduler::Chatbot',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'bulkdata_worker_scheduler',
               'class' => 'Scheduler::Bulkdata',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'notifier_worker_scheduler',
               'class' => 'Scheduler::Notifier',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
]

$redis["local"].with do |r|
  r.keys("*").
    select { |n| n =~ /^queue:/ }.
    each do |rname|
      r.del(rname)
      name = rname.split(/:/).last
      r.srem("queues".freeze, name)
    end
end

Sidekiq.configure_server do |config|
  config.redis = {
    :url    => ENV['REDISTOGO_URL'],
    :driver => :hiredis,
    :size   => (ENV["REDIS_POOL_SIZE"] || 5).to_i
  }

  Sidekiq::Cron::Job.load_from_array cron_jobs
end

Sidekiq.configure_client do |config|
  config.redis = {
    :url    => ENV['REDISTOGO_URL'],
    :driver => :hiredis,
    :size   => (ENV["REDIS_POOL_SIZE"] || 5).to_i
  }

  config.on(:startup) do
    Sidekiq::Queue.all.map { |q| q.clear }
  end
  config.on(:shutdown) do
    Sidekiq::Queue.all.map { |q| q.clear }
  end
end

Sidekiq.default_worker_options = { 'backtrace' => true, 'retry' => 3 }

class SidekiqWebNoSessions < Sidekiq::Web
  disable :sessions
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV['API_USER'] || "consumer",
                       ENV['API_PASSWORD'] || "ruby"]
end
