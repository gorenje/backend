# coding: utf-8
require 'rest-client'
require_relative 'base'
require_relative 'geonames'

module Consumers
  class Chatbot
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :chatbot_consumer

    Car2GoUser         = "Car2goCarSharing"
    ExBerlinerUser     = 'ExBerlinerLocations'
    AbandonedBerlin    = 'AbandonedBerlin'
    BerlinDeDaten      = "BerlinDeDaten"
    BerlinDeKinos      = "BerlinDeKinos"
    UrbaniteNet        = "UrbaniteNet"
    DriveNowCarSharing = "DriveNowCarSharing"
    LuftDaten          = "LuftDatenInfo"
    IndexBerlin        = "IndexBerlin"
    GeonamesOrg        = Consumers::Geonames::Owner

    UnknownCmd = "Sorry Dave, I didn't understand that."

    LuftDatenValueTypeNamesMap = {
      "temperature" => "Temperature",
      "humidity"    => "Humidity",
      "p1"          => "Feinstaub (10 µg/m³)",
      "p2"          => "Feinstaub (2.5 µg/m³)"
    }

    def initialize
      handle_these_events ["chm"]
    end

    def perform
      start_kafka_stream_by_message("chatbot", "chatbotconsumer", kafka_topic)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::ChatbotEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      puts "Chatbot: Found event: #{event}"

      begin
        case true
        when event.is_for?(Car2GoUser)
          handle_car2go_chat(event)
        when event.is_for?(ExBerlinerUser)
          handle_exberliner_chat(event)
        when event.is_for?(AbandonedBerlin)
          handle_abandoned_berlin_chat(event)
        when event.is_for?(BerlinDeDaten)
          handle_berlin_de_chat(event)
        when event.is_for?(BerlinDeKinos)
          handle_berlin_de_kinos_chat(event)
        when event.is_for?(UrbaniteNet)
          handle_urbanite_chat(event)
        when event.is_for?(DriveNowCarSharing)
          handle_drivenow_chat(event)
        when event.is_for?(LuftDaten)
          handle_luftdaten_chat(event)
        when event.is_for?(IndexBerlin)
          handle_indexberlin_chat(event)
        when event.is_for?(GeonamesOrg)
          handle_geonames_chat(event)
        end
      rescue Exception => e
        puts "Chatbot: Errror handling #{event} => #{e.message}"
        puts e.backtrace
      end
    end

    def handle_geonames_chat(event)
      offer, search = event.offer_and_search
      msg = if extdata = offer["extdata"]
              case event.message_text
              when /link/i
                if extdata["link"]
                  extdata["link"]
                else
                  params = {
                    :geonameId => extdata["geoid"],
                    :username  => "gorenje"
                  }
                  data =
                    JSON(RestClient.
                          get("http://api.geonames.org/"+
                           "getJSON?#{URI.encode_www_form(params)}")) rescue {}

                  an = data["alternateNames"]
                  if an && !(links = an.select {|a| a["lang"] == "link"}).empty?
                    links.first["name"]
                  else
                    "http://api.geonames.org/" +
                      "getJSON?geonameId=#{extdata["geoid"]}&username=demo"
                  end
                end
              else
                UnknownCmd
              end
            else
              UnknownCmd
            end

      event.post_message(msg, GeonamesOrg)
    end

    def handle_drivenow_chat(event)
      event.post_message(UnknownCmd, DriveNowCarSharing)
    end

    def handle_indexberlin_chat(event)
      offer, search = event.offer_and_search
      msg =
        if extdata = offer["extdata"]
          case event.message_text
          when /link/i
            extdata["elink"].empty? ? extdata["ilink"] : extdata['elink']
          when /open/i
            extdata["otime"]
          when /tele/i
            extdata["tel"]
          when /all/i
            extdata.map do |k,v|
              next if ["id", "vid"].include?(k)
              "#{k}: #{v}"
            end.compact.join(",\n")
          end
        end || UnknownCmd

      event.post_message(msg, IndexBerlin)
    end

    def handle_luftdaten_chat(event)
      offer, search = event.offer_and_search

      msg = if extdata = offer["extdata"]
              case event.message_text
              when /link/i
                "http://api.luftdaten.info/v1/sensor/%s/" % extdata["sid"]
              else
                urlstr =
                  "http://api.luftdaten.info/v1/sensor/%s/" % extdata["sid"]
                begin
                  data = JSON(mechanize_agent.get(urlstr).body)
                  newestdp = data.last
                  value_type = extdata["id"].split(/:/).first

                  values = if value_type == "ht"
                             newestdp["sensordatavalues"].select do |sdata|
                               ["temperature","humidity"].
                                 include?(sdata["value_type"].downcase)
                             end
                           else
                             newestdp["sensordatavalues"].select do |sdata|
                               ["p1","p2"].
                                 include?(sdata["value_type"].downcase)
                             end
                           end

                  str = values.map do |senvalues|
                    "%s: %s" %
                      [LuftDatenValueTypeNamesMap[senvalues["value_type"].
                                                    downcase],
                       senvalues["value"]]
                  end.join(", ")
                  "Current values: #{str}"
                rescue Exception => e
                  puts "LuftDaten failed: #{e.message}"
                  puts e.backtrace
                  UnknownCmd
                end
              end
            end || UnknownCmd

      event.post_message(msg, LuftDaten)
    end

    def handle_urbanite_chat(event)
      offer, search = event.offer_and_search
      msg = case event.message_text
            when /link/i
              offer["extdata"]["link"] || offer["extdata"]["id"]
            when /url/i
              "Url #{offer["extdata"]["link"]}"
            else
              (offer["extdata"].keys.include?(event.message_text.downcase) &&
               offer["extdata"][event.message_text.downcase]) || UnknownCmd
            end

      event.post_message(msg, UrbaniteNet)
    end

    def handle_berlin_de_kinos_chat(event)
      offer, search = event.offer_and_search
      if offer.nil? || offer["extdata"].nil? || offer["extdata"]["id"].blank?
        return event.
                 post_message("Sorry, film has ended. No information available.",
                              BerlinDeKinos)
      end

      extdata = offer["extdata"]
      filmurl, kinoid, starttime = extdata["id"].split(/\|/)

      msg = case event.message_text
            when /when/i
              "Starting at #{extdata["berlin_time"]} @ #{extdata["where"]}"
            when /wherelse/i
              begin
                result = []
                page = mechanize_agent.get(filmurl)
                page.search("div#kino_accordeon > div").
                  each_slice(2) do |name,program|
                  result << name.search("a").text
                end
                if_blank(result.join(", "), "Not screening anywhere else")
              rescue Exception => e
                "Found Nothing"
              end
            when /desc/i
              "Check out #{filmurl}"
            when /link/i
              filmurl
            else
              UnknownCmd
            end

      event.post_message(msg, BerlinDeKinos)
    end

    def handle_berlin_de_chat(event)
      offer, search = event.offer_and_search
      type, idstr = offer["extdata"]["id"].split(/:/)

      msg = case type
            when "markt"
              urlstr = "http://www.berlin.de/sen/wirtschaft/service/"+
                       "maerkte-feste/wochen-troedelmaerkte/index.php/index/"+
                       "all.json?q="

              data = JSON(mechanize_agent.get(urlstr).body) rescue {"index"=>[]}
              object = data["index"].select { |a| a["id"] == idstr }.first

              if object
                case event.message_text
                when /open/i
                  "Opening times: #{object['tage']} from #{object['zeiten']}"
                when /contact/
                  object["betreiber"]
                when /misc/i
                  misc = if_blank(object['bemerkungen'],'Nothing unusual')
                  "Misc info: #{misc}"
                when /location/i
                  object["location"]
                else
                  UnknownCmd
                end
              else
                "Nothing found"
              end
            when "denkmal"
              case event.message_text
              when /link/i
                "http://www.stadtentwicklung."+
                  "berlin.de/denkmal/liste_karte_datenbank/de/denkmaldaten"+
                  "bank/daobj.php?obj_dok_nr=" + idstr
              else
                ("Details can be found here: http://www.stadtentwicklung."+
                 "berlin.de/denkmal/liste_karte_datenbank/de/denkmaldaten"+
                 "bank/daobj.php?obj_dok_nr=" + idstr)
              end
            else
              UnknownCmd
            end

      event.post_message(msg, BerlinDeDaten)
    end

    def handle_abandoned_berlin_chat(event)
      offer, search = event.offer_and_search
      msg = case event.message_text
            when /link/i
              offer["extdata"]["id"]
            else
              "Details can be found here: " + offer["extdata"]["id"]
            end
      event.post_message(msg, AbandonedBerlin)
    end

    def handle_exberliner_chat(event)
      offer, search = event.offer_and_search

      msg = case event.message_text
            when /desc/i
              t = offer["extdata"]["desc"]
              t.blank? ? "No description" : t
            when /phone/i
              page = mechanize_agent.get(offer["extdata"]["id"])
              page.search("div[class='mp-loc-phone']").search("a").
                children.first.content rescue "No Phone"
            when /open/i
              page = mechanize_agent.get(offer["extdata"]["id"])
              page.search("div[class='mp-loc-hours']").search("pre").
                children.first.content rescue "Don't know"
            when /cuisine/i
              page = mechanize_agent.get(offer["extdata"]["id"])
              page.search("div[class='mp_tag_cat_75']").search("span").
                children.first.content rescue "No Cuisine"
            when /link/i
              offer["extdata"]["id"]
            else
              UnknownCmd
            end

      event.post_message(msg, ExBerlinerUser)
    end

    def handle_car2go_chat(event)
      offer, search = event.offer_and_search

      msg = if car_gone?(offer)
              "Sorry, car has already been reserved"
            else
              case event.message_text
              when /link/i
                car2go_reserve_url(offer)
              else
                reserve_url = car2go_reserve_url(offer)
                "Hi there, you can reserve your car by clicking on " +
                  "#{reserve_url} - Have fun!"
              end
            end

      event.post_message(msg, Car2GoUser)
    end

    def car2go_reserve_url(offer)
      vin    = offer["extdata"]["vin"]
      latlng = offer["location"]["coordinates"].reverse.join(",")
      "https://car2go.com/vehicle/%s?latlng=%s" % [ vin, latlng ]
    end

    def car_gone?(offer)
      offer["validuntil"] < Time.now.utc.strftime("%s%L").to_i
    end

    def if_blank(str, default)
      str.blank? ? default : str
    end

    def mechanize_agent(user_agent = :use_mozilla)
      Mechanize.new.tap do |agent|
        agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        if user_agent == :use_mozilla
          agent.user_agent_alias = 'Linux Mozilla'
        else
          agent.user_agent = user_agent
        end
      end
    end
  end
end
