require_relative 'event'

module Consumers
  module Kafka
    class GeoEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def device_id
        params[:di].try(:first)
      end

      def latitude
        params[:lt].try(:first)
      end

      def longitude
        params[:lg].try(:first)
      end

      def accuracy
        params[:a].try(:first)
      end

      def param_string
        @_params
      end
    end
  end
end
