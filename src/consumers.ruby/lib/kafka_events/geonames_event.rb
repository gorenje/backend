require_relative 'event'
require 'digest/sha2'

module Consumers
  module Kafka
    class GeonamesEvent < Consumers::Kafka::Event
      LatLngRegExp = /latitude.+"([0-9\.]+)".+longitude.+"([0-9\.]+)"/

      def initialize(payload)
        super(payload)
      end

      def keywords
        @keywords ||= params[:kw].try(:first)
      end

      def action
        @action ||= params[:action].try(:first)
      end

      def sw
        @sw ||= _lat_lng(params[:sw].try(:first))
      end

      def ne
        @ne ||= _lat_lng(params[:ne].try(:first))
      end

      def south
        sw[:latitude]
      end

      def east
        ne[:longitude]
      end

      def north
        ne[:latitude]
      end

      def west
        sw[:longitude]
      end

      def query
        {}.tap do |h|
          str = keywords.downcase.split(/[[:space:]]+/).
                  reject {|a| a =~ /^#/}.join(" ")
          h[:q] = str unless str.blank?
        end
      end

      def hashterms
        keywords.downcase.split(/[[:space:]]+/).select { |a| a =~ /^#/ }
      end

      def features
        hshs = hashterms
        {}.tap do |h|
          if hshs.include?("#hotel")
            h[:featureclass] = "S"
            h[:featureCode]  = "HTL"
          end
        end
      end

      def wikipedia_url(opts = {})
        l1 = Geokit::LatLng.new(south.to_f, east.to_f)
        l2 = Geokit::LatLng.new(north.to_f, west.to_f)

        midpoint = l2.midpoint_to(l1)

        params = {
          :username => "gorenje",
          :lat      => midpoint.lat,
          :lng      => midpoint.lng,
          :radius   => (l1.distance_to(l2) / 2000.0).ceil,
          :maxRows  => 200,
          :startRow => 0
        }.merge(opts)

        "http://api.geonames.org/findNearbyWikipediaJSON?"+
          "#{params_to_query(params)}"
      end

      def search_url(opts = {})
        params = {
          :username => "gorenje",
          :east     => east,
          :west     => west,
          :north    => north,
          :south    => south,
          :maxRows  => 200,
          :startRow => 0
        }.merge(features).merge(query).merge(opts)

        "http://api.geonames.org/searchJSON?#{params_to_query(params)}"
      end

      def offers
        data = JSON(RestClient.get(search_url)) rescue {}
        data["geonames"] || []
      end

      def offers_wikipedia
        data = JSON(RestClient.get(wikipedia_url)) rescue {}
        (data["geonames"] || []).map do |hsh|
          hsh.tap do |h|
            h["toponymName"] = h["title"]
            if h["geoNameId"]
              h["geonameId"] = h["geoNameId"]
            else
              h["extdata"] = { "link" => "https://" + h["wikipediaUrl"] }
              h["geonameId"] = Digest::SHA256.hexdigest(h["wikipediaUrl"])
            end
          end
        end
      end

      private

      def params_to_query(params)
        uri = Addressable::URI.new
        uri.query_values = params
        uri.query
      end

      def _lat_lng(str)
        if str =~ LatLngRegExp
          { :latitude => $1.to_f, :longitude => $2.to_f }
        else
          {}
        end
      end
    end
  end
end