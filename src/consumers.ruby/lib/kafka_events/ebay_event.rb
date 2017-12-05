require_relative 'event'

module Consumers
  module Kafka
    class EbayEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def lat
        params[:lat].try(:first).to_f
      end

      def lng
        params[:lng].try(:first).to_f
      end

      def latDelta
        params[:latD].try(:first).to_f
      end

      def lngDelta
        params[:lngD].try(:first).to_f
      end

      def search_id
        params[:_id].try(:first)
      end

      def title
        params[:title].try(:first)
      end

      def search_obj
        !search_id.blank? && StoreHelper.object(search_id)
      end

      def action
        params[:action].try(:first)
      end

      def coordinates
        [lat, lng].compact
      end

      def radius
        Geocoder::Calculations.
          distance_between([lat+latDelta, lng+lngDelta],
                           [lat-latDelta, lng-lngDelta]) / 2.0
      end

      def url_path
        return nil if title.blank?
        results = Geocoder.search(coordinates).first
        "/s-#{results.postal_code}/#{URI.escape(title)}/k0l3520r#{radius.ceil}"
      end
    end
  end
end
