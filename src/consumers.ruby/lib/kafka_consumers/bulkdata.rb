require_relative 'base'

module Consumers
  class Bulkdata
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :bulkdata_consumer

    def initialize
      handle_these_events ["bud"]
    end

    def perform
      start_kafka_stream_by_message("bulkdata", "bulkdataconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::BulkdataEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      puts "Bulkdata: Found event: #{event}"

      return if event.owner.blank?

      begin
        StoreHelper::Agent.new.bulk.notify_searchers.
          send(CGI.escape(event.owner)).get
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end
