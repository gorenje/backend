require_relative 'base'

module Consumers
  class Geonames
    include Consumers::Base
    include Sidekiq::Worker

    Owner = "GeonamesOrg"

    BaseOffer = {
      :owner         => Owner,
      :text          => "",
      :keywords      => "",
      :validfrom     => 0,
      :validuntil    => -1,
      :isMobile      => false,
      :allowContacts => true,
      :showLocation  => true,
      :extdata       => {},
      :location      => {
        :type        => "Point",
        :coordinates => [ 0, 0 ],
      },
      :radiusMeters  => 225,
    }

    SevenDaysMs = 7 * 24 * 60 * 60 * 1000

    sidekiq_options :queue => :geonames_consumer

    def initialize
      handle_these_events ["offr"]
    end

    def perform
      start_kafka_stream_by_message("geonames", "geonamesconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::GeonamesEvent.new(message.value).tap do |event|
        if event.action == "search" && (event.keywords =~ /#poi/i ||
                                        event.keywords =~ /#wikipedia/i)
          begin
            handle_event(event)
          rescue Exception => e
            puts "Geonames: Handling event failed: #{e.message}"
            puts e.backtrace
          end
        end
      end
    end

    def handle_event(event)
      puts "Geonames: Found event: #{event}"

      return if event.sw.empty? || event.ne.empty?

      old_offers = StoreHelper.offers_for_owner(Owner,event.sw,event.ne)
      new_offers = []
      timestamp  = Time.now.utc.strftime("%s%L").to_i

      if event.keywords =~ /#poi/i
        event.offers
      else
        event.offers_wikipedia
      end.shuffle[0..50].each do |geoname|
        offr = old_offers.
                 select { |a| a["extdata"]["geoid"] == geoname["geonameId"] }.
                 first || (new_offers << JSON(BaseOffer.to_json)).last

        offr.tap do |d|
          d["location"]["coordinates"] =
            [geoname["lng"].to_f, geoname["lat"].to_f]
          d["text"]       = geoname["toponymName"]
          d["extdata"]    = (geoname["extdata"] || {}).
                              merge({ :geoid => geoname["geonameId"] })
          d["validuntil"] = timestamp + SevenDaysMs
          d["keywords"]   = event.hashterms.join(" ")
        end
      end

      remove_offers,old_offers =
                    old_offers.partition {|offr| offr["validuntil"] < timestamp}

      send_off(new_offers, old_offers, remove_offers)
    end

    def send_off(new_offers, old_offers, remove_offers = [])
      if new_offers.count < 1000 && old_offers.count < 1000 &&
         remove_offers.count < 1000
        send_off_immediately(new_offers, old_offers)
        send_off_immediately([], [], remove_offers)
      else
        new_offers.each_slice(1500) { |ary| send_off_immediately(ary, []); }
        old_offers.each_slice(1500) { |ary| send_off_immediately([], ary); }
        remove_offers.each_slice(1500) do |ary|
          send_off_immediately([], [], ary);
        end
      end
      TrackerHelper.bulk_update_done(Owner)
      GC.start
    end

    def send_off_immediately(new_offers, old_offers, remove_offers = [])
      data = {
        :new_offers    => new_offers,
        :old_offers    => old_offers,
        :remove_offers => remove_offers
      }

      puts StoreHelper::Agent.new.bulk.offers.post(data)
    end

  end
end
