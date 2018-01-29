# config/unicorn.rb
require 'unicorn'

worker_processes Integer(ENV['WEB_CONCURRENCY'] || 2)
timeout          Integer(ENV['WEB_TIMEOUT'] || 15)
preload_app      true

# As recommended by HEROKU for running on HEROKU:
# https://devcenter.heroku.com/articles/rails-unicorn
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
end

# As recommended by HEROKU for running on HEROKU:
# https://devcenter.heroku.com/articles/rails-unicorn
after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end
end
