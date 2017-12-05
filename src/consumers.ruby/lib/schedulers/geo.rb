require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Geo < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Geo
    end
  end
end
