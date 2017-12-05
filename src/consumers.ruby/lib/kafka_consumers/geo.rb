require_relative 'base'

module Consumers
  class Geo
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :geo_consumer

    def initialize
      handle_these_events ["geo"]
    end

    def perform
      start_kafka_stream_by_message("geo", "geoconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::GeoEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      puts "Geo: Found event: #{event}"

      begin
        StoreHelper::Agent.new.store.geo.get(event.param_string)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end
