require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Notifier < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Notifier
    end
  end
end
