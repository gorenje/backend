# Import temperature, humdity, pressure and dirt-in-the-air measurements.
#
# For more details, see luftdaten.info
# For API details: https://github.com/opendata-stuttgart/meta/wiki/APIs
#
class LuftDatenImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#luftdaten"].map(&:downcase)
  Owner        = "LuftDatenInfo"

  include BaseImporter

  def sensor_hash_to_readings(sensorhsh)
    sensorid = sensorhsh["sensor"]["id"]
    sensorhsh["sensordatavalues"].map do |sendata|
      OpenStruct.
        new({}.tap do |h|
              h["sid"]  = sensorid
              h["id"]   = "%s:%s" % [sendata["value_type"], sensorid]
              h["text"] = "%s: %s" % [sendata["value_type"].capitalize,
                                      sendata["value"]]
              h["lat"] = sensorhsh["location"]["latitude"]
              h["lng"] = sensorhsh["location"]["longitude"]
              h["keywords"] = ["##{sendata["value_type"]}"].map(&:downcase)
            end)
    end
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    idmap = {}.tap do |idm|
      old_offers.each { |ofr| idm[ofr["extdata"]["id"]] = ofr }
    end

    JSON(RestClient.get("http://api.luftdaten.info/static/v2/data.json")).
      each do |sensorhsh|

      sensor_hash_to_readings(sensorhsh).each do |reading|
        offr = idmap[reading.id] ||
               new_offers.
                 select { |a| a["extdata"]["id"] == reading.id }.first ||
               (new_offers << JSON(base_data.to_json)).last

        offr.tap do |d|
          d["text"]                    = reading.text
          d["validuntil"]              = timestamp + TwentyMinutesMS
          d["location"]["coordinates"] = [reading.lng, reading.lat]
          d["extdata"]                 = { :id => reading.id,
                                           :sid =>  reading.sid }
          d["keywords"] = BaseKeyWords + reading.keywords
        end
      end
    end

    send_off(new_offers, old_offers)
  end
end
