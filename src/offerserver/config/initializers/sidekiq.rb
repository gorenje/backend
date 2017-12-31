require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

require_relative 'redis'

cron_jobs = [{
    'name'  => 'car2go_importer',
    'class' => 'CarToGoImporter',
    'cron'  => '30 */1 * * * *',
    'args'  => nil
  },
  {
    'name'  => 'drivenow_importer',
    'class' => 'DriveNowImporter',
    'cron'  => '10 */1 * * * *',
    'args'  => nil
  },
  {
    'name'  => 'exberliner_importer',
    'class' => 'ExberlinerImporter',
    'cron'  => '0 0,3,6,9,12,15,18,21 * * *',
    'args'  => nil
  },
  {
    'name'  => 'abandoned_berlin_importer',
    'class' => 'AbandonedBerlinImporter',
    'cron'  => '10 0,3,6,9,12,15,18,21 * * *',
    'args'  => nil
  },
  {
    'name'  => 'berlin_de_importer',
    'class' => 'BerlinDeImporter',
    'cron'  => '20 0,2,4,6,8,10,12,14,16,18,20,22 * * *',
    'args'  => nil
  },
  {
    'name'  => 'berlin_de_natur',
    'class' => 'BerlinNaturImporter',
    'cron'  => '30 1,3,5,7,9,11,13,15,17,19,21,23 * * *',
    'args'  => nil
  },
  {
    'name'  => 'urbanite_net',
    'class' => 'UrbaniteNetImporter',
    'cron'  => '10 1,3,5,7,9,11,13,15,17,19,21,23 * * *',
    'args'  => nil
  },
  {
    'name'  => 'luft_daten_importer',
    'class' => 'LuftDatenImporter',
    'cron'  => '50 */10 * * * *',
    'args'  => nil
  },
  {
    'name'  => 'index_berlin_importer',
    'class' => 'IndexBerlinImporter',
    'cron'  => '45 0,3,6,9,12,15,18,21 * * *',
    'args'  => nil
  },
  {
    'name'  => 'berlin_kinos_import',
    'class' => 'BerlinDeKinosImporter',
    'cron'  => '45 */1 * * *',
    'args'  => nil
  },
]


Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis, :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }

  Sidekiq::Cron::Job.load_from_array cron_jobs
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis, :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }
end

Sidekiq.default_worker_options = { 'backtrace' => true }

class SidekiqWebNoSessions < Sidekiq::Web
  disable :sessions
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV['API_USER'] || "offer",
                       ENV['API_PASSWORD'] || "user"]
end
