# coding: utf-8
class RakeWorker
  include Sidekiq::Worker

  def initialize
  end

  def perform(args)
    unless (r = system("bundle exec rake #{args["cmd"]}"))
      raise "Command #{args["cmd"]} failed. Should be retried. "+
            "(response was '#{r}')"
    end
  end
end
