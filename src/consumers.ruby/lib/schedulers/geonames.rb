require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Geonames < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Geonames
    end
  end
end
