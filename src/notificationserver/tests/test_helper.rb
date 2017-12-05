ENV['RAILS_ENV']    = 'test' # ensures that settings.environment == 'test'
ENV['RACK_ENV']     = 'test'
ENV['IP']           = 'www.example.com'
ENV['PORT']         = '9999'
ENV['TZ']           = 'UTC'

require "bundler/setup"

# kinda cheating but needed if a test is called directly using ruby:
#   ruby test/unit/...._test.rb
if ENV['DATABASE_URL'].nil? && File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

unless ENV['DATABASE_URL'] =~ /_test$/
  ENV['DATABASE_URL'] = ENV['DATABASE_URL'] + "_test"
end

require 'rack/test'
require 'shoulda'
require 'rr'
# use binding.pry at any point of the tests to enter the pry shell
# and pock around the current object and state
#    https://github.com/pry/pry/wiki/Runtime-invocation
require 'pry'
require 'fakeweb'
require 'minitest/autorun'

require_relative '../application.rb'

raise "Not Using Test Environment" if settings.environment != 'test'

class Minitest::Test
  include RR::Adapters::TestUnit

  def _pry
    binding.pry
  end

  def assert_zero(val, msg = nil)
    assert_equal 0, val, msg
  end

  def assert_one(val, msg = nil)
    assert_equal 1, val, msg
  end

  def assert_not_match(regexp, str, msg = nil)
    assert !(str =~ regexp), msg
  end

  def make_kafka_message(msg)
    OpenStruct.new({:offset => 1, :value => msg})
  end

  def replace_in_env(changes)
    original_values = Hash[changes.map { |k,_| [k,ENV[k] ]}]
    changes.each { |k,v| ENV[k] = v }
    yield
  ensure
    original_values.each { |key,value| ENV[key] = value }
  end

  def add_to_env(changes)
    changes.each { |k,v| ENV[k] = v }
    yield
  ensure
    changes.keys.each { |key| ENV.delete(key) }
  end

  def assert_redirect_to(path, msg = nil)
    assert(last_response.redirect?,
           "Request was not redirect" + (msg ? " (#{msg})" : ""))
    assert_equal('http://example.org/%s' % [path],
                 last_response.headers["Location"],
                 "Redirect location didn't match"+ (msg ? " (#{msg})" : ""))
  end

  def silence_is_golden
    old_stderr,old_stdout,stdout,stderr =
      $stderr, $stdout, StringIO.new, StringIO.new

    $stdout = stdout
    $stderr = stderr
    result = yield
    [result, stdout.string, stderr.string]
  ensure
    $stderr, $stdout = old_stderr, old_stdout
  end
end
