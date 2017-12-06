module Consumers
  module Kafka
    class Event
      attr_reader :type, :payload, :params, :meta

      def initialize(payload)
        @payload = payload

        # we purposely delay the parsing of the meta & params strings
        # so that a consumer can reject this event if it's type doesn't
        # match what it wants.
        typestr, @_meta, @_params = @payload.split(' ')

        @type = typestr.split('/').last
      end

      def params
        @params ||= CGI.parse(@_params).symbolize_keys
      end

      def meta
        @meta ||= CGI.parse(@_meta).symbolize_keys
      end

      [:device, :country, :ip, :platform, :ts, :bot_name,
       :device_name, :klag].each do |attr|
        define_method(attr) do
          (meta[attr] || []).first
        end
      end

      alias_method :call, :type

      def delay_in_seconds
        ((Time.now.to_f * 1000).to_i - ts.to_i) / 1000
      end

      def adid
        adid = (params[:adid] || []).first
        (adid && adid != "null" &&
         adid != "undefined" && !(adid =~ /^[0-]+$/) &&
         adid != "" && adid) || nil
      end
      alias_method :idfa, :adid

      def gadid
        gadid = (params[:gadid] || []).first
        (gadid && gadid != "null" &&
         gadid != "undefined" && !(gadid =~ /^[0-]+$/) &&
         gadid != "" && gadid) || nil
      end

      def gadid_has_valid_format?
        !!(/^[a-f0-9]{4}([a-f0-9]{4}-){4}[a-f0-9]{12}$/i =~ gadid)
      end

      def uuid
        uuid = (params[:uuid] || []).first
        (uuid && uuid != "null" &&
         uuid != "undefined" && !(uuid =~ /^[0-]+$/) &&
         uuid != "" && uuid) || nil
      end

      def time
        @time ||= Time.at(ts.to_i/1000)
      end

      def ip_dot_notation
        int_to_ip(ip)
      end

      def to_s
        @payload
      end

      private

      def int_to_ip(i)
        begin
          return IPAddr.new(i.to_i, Socket::AF_INET).to_s
        rescue
          begin
            return IPAddr.new(i.to_i, Socket::AF_INET6).to_s
          rescue
            return "0"
          end
        end
      end
    end
  end
end
