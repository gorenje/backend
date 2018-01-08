# coding: utf-8
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

  AcceptedValueTypes = ["temperature", "humidity", "p1", "p2"]

  ValueTypeNames = {
    "temperature" => "Temperature",
    "humidity"    => "Humidity",
    "p1"          => "Feinstaub (10 µg/m³)",
    "p2"          => "Feinstaub (2.5 µg/m³)"
  }

  def sensor_hash_to_readings(sensorhsh)
    sensorid = sensorhsh["sensor"]["id"]
    sensorhsh["sensordatavalues"].map do |sendata|
      value_type = sendata["value_type"].downcase
      next unless AcceptedValueTypes.include?(value_type)

      extra_keywords = value_type =~ /^p/ ? ["#feinstaub"] : []
      OpenStruct.
        new({}.tap do |h|
              h["sid"]  = sensorid
              h["id"]   = "%s:%s" % [value_type, sensorid]
              h["text"] = "%s: %s" % [ValueTypeNames[value_type] ||
                                      value_type.capitalize,
                                      "%0.2f" % sendata["value"].to_f]
              h["lat"] = sensorhsh["location"]["latitude"]
              h["lng"] = sensorhsh["location"]["longitude"]
              h["keywords"] = ["##{value_type}"] + extra_keywords
              h["_grp"] = "%s:%s" % [sensorid, value_type =~ /^p/ ? "f" : "t"]
            end)
    end.compact.group_by { |a| a._grp }.
      map do |key,values|
      rval    = values.first
      rval.id = key =~ /:f$/ ? "fe:%s" % rval.sid : "ht:%s" % rval.sid

      rval.keywords += values.last.keywords
      rval.keywords = rval.keywords.uniq
      rval.text += ", " + values.last.text
      rval
    end.flatten
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

    (JSON(RestClient.get("http://api.luftdaten.info/static/v2/data.json")) ||
      JSON(RestClient.get("http://api.luftdaten.info/static/v1/data.json"))).
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
          d["extdata"]                 = { :id  => reading.id,
                                           :sid => reading.sid }
          d["keywords"] = BaseKeyWords + reading.keywords
        end
      end
    end

    remove_offers, old_offers =
      old_offers.partition { |offr| offr["validuntil"] < timestamp }

    send_off(new_offers, old_offers, remove_offers)
  end
end
