require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Chatbot < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Chatbot
    end
  end
end
