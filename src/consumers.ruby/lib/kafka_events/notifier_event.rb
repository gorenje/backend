require_relative 'event'

module Consumers
  module Kafka
    class NotifierEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def obj_id
        params[:_id].try(:first)
      end

      def action
        params[:action].try(:first)
      end
    end
  end
end
