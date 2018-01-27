require_relative 'base'

module Consumers
  class Notifier
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :notifier_consumer

    IgnoreActions = ["delete","search"]

    def initialize
      handle_these_events ["srch", "offr"]
    end

    def perform
      start_kafka_stream_by_message("notifier", "notifierconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::NotifierEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      return if IgnoreActions.include?(event.action) || event.obj_id.blank?

      begin
        case event.type
        when "srch"
          StoreHelper::Agent.new.searches.send(event.obj_id).notify.get
        when "offr"
          StoreHelper::Agent.new.offers.send(event.obj_id).notify.get
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end
