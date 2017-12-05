require_relative 'event'

module Consumers
  module Kafka
    class BulkdataEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def owner
        params[:owner].try(:first)
      end
    end
  end
end
