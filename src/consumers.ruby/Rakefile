ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'
require 'fileutils'
require 'yaml'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

# hack to differentiate databases when doing tests & running development
ENV['DATABASE_URL'] = ENV['DATABASE_URL'] + "_test" if ENV['RACK_ENV'] == 'test'

Dir[File.join(File.dirname(__FILE__), 'lib', 'tasks','*.rake')].
  each { |f| load f }

# to generate an initial .env, don't need a database
if ENV['DATABASE_URL']
  require 'active_record_migrations'
  ActiveRecordMigrations.configure do |c|
    c.database_configuration = ActiveRecord::Base.configurations
    c.environment            = ENV['RACK_ENV']
    c.db_dir                 = 'config/db'
    c.migrations_paths       = ['config/db/migrations']
  end
  ActiveRecordMigrations.load_tasks
end

task :environment do
  require_relative 'application'
end

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
