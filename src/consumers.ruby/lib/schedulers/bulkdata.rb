require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Bulkdata < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Bulkdata
    end
  end
end
