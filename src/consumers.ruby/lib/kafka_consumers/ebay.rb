require_relative 'base'

module Consumers
  class Ebay
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :ebay_consumer

    BaseUrl  = "https://www.ebay-kleinanzeigen.de"
    Owner    = "EbayKleinanzeigen"
    TwentyFourHoursMS = 24 * 60 * 60 * 1000

    BaseOffer = {
      :owner         => Owner,
      :text          => "",
      :keywords      => [""],
      :validfrom     => 0,
      :validuntil    => -1,
      :isMobile      => false,
      :allowContacts => true,
      :showLocation  => true,
      :extdata       => {},
      :images        => [],
      :location => {
        :type        => "Point",
        :coordinates => [ 0, 0 ],
        :dimension   => {
          :longitudeDelta => 0.0017342150719485971,
          :latitudeDelta => 0.0017342150719485971
        },
        :place => {
          :en  => {
            :locality => "Berlin",
            :country  => "Germany",
            :route    => ""
          }
        }
      }
    }

    class AdWrapper
      def initialize(event,elem)
        @elem  = elem
        @event = event
      end

      def adid
        @elem.search("[data-adid]").attr("data-adid").value
      end

      def ebay_url
        URI.join(BaseUrl,
                 @elem.search(".text-module-begin > a").
                 attr("href").value).to_s rescue nil
      end

      def image_url
        @elem.search("div.imagebox").first.attr("data-imgsrc")
      end

      def text
        @elem.search(".text-module-begin > a").text
      end

      def created_at
        @elem.search(".aditem-addon").text.strip
      end

      def price
        @elem.search(".aditem-details > strong").text
      end

      def timestamp
        Time.now.utc.strftime("%s%L").to_i
      end

      def create_offer
        return nil if text.blank? || ebay_url.blank?

        begin
          JSON(BaseOffer.to_json).tap do |offer|
            image_id = ImageHelper.upload_url(image_url) rescue nil

            offer["images"]     = [image_id] if image_id
            offer["text"]       = text
            offer["validfrom"]  = timestamp - 10000
            offer["validuntil"] = timestamp + TwentyFourHoursMS
            offer["keywords"]   = @event.title.downcase.split

            offer["location"]["coordinates"] = [@event.lng, @event.lat]
            offer["location"]["dimension"]["longitudeDelta"] = @event.lngDelta
            offer["location"]["dimension"]["latitudeDelta"] = @event.latDelta

            offer["extdata"] = {
              "adid"    => adid,
              "url"     => ebay_url,
              "created" => created_at,
              "price"   => price
            }
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace
          nil
        end
      end

      def store_offer
        offer = create_offer
        StoreHelper::Agent.new.offers.post(offer) if offer
      end
    end

    def initialize
      handle_these_events ["srch"]
      @handled_offsets = Hash.new{ |hsh, key| hsh[key] = [] }
    end

    def perform
      start_kafka_stream_by_message("geo", "ebayconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def handled?(message)
      @handled_offsets[message.partition].include?(message.offset).tap do
        @handled_offsets[message.partition] << message.offset
      end
    end

    def do_work(message)
      unless handled?(message)
        Consumers::Kafka::EbayEvent.new(message.value).tap do |event|
          handle_event(event)
        end
      end
    end

    def handle_event(event)
      return if event.url_path.blank? || event.action != "create"

      puts "Ebay Found event: #{event}"

      begin
        agent = MechanizeHelper.agent
        agent.set_proxy("kafka.adtek.io", 3128)
        agent.get(BaseUrl + event.url_path).
          search("li.ad-listitem").each do |elem|
          AdWrapper.new(event,elem).store_offer
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end
