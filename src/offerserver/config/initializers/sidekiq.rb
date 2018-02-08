require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

require_relative 'redis'

cron_jobs = [{
    'name'  => 'exberliner_importer',
    'class' => 'RakeWorker',
    'cron'  => '0 0,3,6,9,12,15,18,21 * * *',
    'args'  => { :cmd => "exberliner:update" }
  },
  {
    'name'  => 'abandoned_berlin_importer',
    'class' => 'RakeWorker',
    'cron'  => '10 0,3,6,9,12,15,18,21 * * *',
    'args'  => { :cmd => "abandonedberlin:update" }
  },
  {
    'name'  => 'berlin_de_natur',
    'class' => 'RakeWorker',
    'cron'  => '30 1,3,5,7,9,11,13,15,17,19,21,23 * * *',
    'args'  => { :cmd => "berlinnatur:update" }
  },
  {
    'name'  => 'urbanite_net',
    'class' => 'RakeWorker',
    'cron'  => '10 1,3,5,7,9,11,13,15,17,19,21,23 * * *',
    'args'  => { :cmd => "urbanitenet:update" }
  },
  {
    'name'  => 'luft_daten_importer',
    'class' => 'RakeWorker',
    'cron'  => '50 */10 * * * *',
    'args'  => { :cmd => "luftdaten:update" }
  },
  {
    'name'  => 'index_berlin_importer',
    'class' => 'RakeWorker',
    'cron'  => '45 0,3,6,9,12,15,18,21 * * *',
    'args'  => { :cmd => "indexberlin:update" }
  },
  {
    'name'  => 'berlin_kinos_import',
    'class' => 'RakeWorker',
    'cron'  => '45 */1 * * *',
    'args'  => { :cmd => "berlindekinos:update" }
  },
]

["de","es","en"].each_with_index do |lang, idx|
  crontimes = ["25 2,5,8,11,14,17,20,23 * * *",
               "25 1,4,7,10,13,16,19,22 * * *",
               "25 0,3,6,9,12,15,18,21 * * *"]

  cron_jobs << {
    'name'  => "newstral_#{lang}_import",
    'class' => 'RakeWorker',
    'cron'  => crontimes[idx % 3],
    'args'  => { :cmd => "newstralcom:update[#{lang}]" }
  }
end

12.times do |idx|
  crontimes = [" 0 0,6,12,18 * * *",
               "20 0,6,12,18 * * *",
               "40 0,6,12,18 * * *",
               " 0 1,7,13,19 * * *",
               "20 1,7,13,19 * * *",
               "40 1,7,13,19 * * *",
               " 0 2,8,14,20 * * *",
               "20 2,8,14,20 * * *",
               "40 2,8,14,20 * * *",
               " 0 3,9,15,21 * * *",
               "20 3,9,15,21 * * *",
               "40 3,9,15,21 * * *"]

  cron_jobs << {
    'name'  => "meetup_com_import_#{idx}",
    'class' => 'RakeWorker',
    'cron'  => crontimes[idx],
    'args'  => { :cmd => "meetupcom:update[#{300*idx},#{300*(idx+1)}]" }
  }
end

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
