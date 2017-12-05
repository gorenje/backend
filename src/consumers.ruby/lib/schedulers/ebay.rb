require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Ebay < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Ebay
    end
  end
end
