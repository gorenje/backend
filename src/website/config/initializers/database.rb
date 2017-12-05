require 'yaml'
require 'active_record'
require 'active_support'
require 'pg'

if ENV['DATABASE_URL']
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::ConnectionAdapters::ConnectionSpecification::
      ConnectionUrlResolver.new(ENV['DATABASE_URL']).to_hash.tap do |h|
      h["pool"]             = ENV['DB_POOL_SIZE'] || 20
      h["timeout"]          = ENV['DB_TIMEOUT_MSEC'] || 5000
      h["checkout_timeout"] = ENV['DB_CHECKOUT_TIMEOUT_MSEC'] || 20000
    end
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RACK_ENV'] == 'development'

    Dir[File.join(File.dirname(__FILE__), '..','..','models','*.rb')].each do |f|
      require_relative f
    end
  end
end
