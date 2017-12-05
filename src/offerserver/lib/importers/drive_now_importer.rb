class DriveNowImporter
  include Sidekiq::Worker

  BaseText     = "CarSharing DriveNow %s"
  BaseKeyWords = ["CarSharing", "DriveNow", "#car", "#all"].map(&:downcase)
  Owner        = "DriveNowCarSharing"

  include BaseImporter

  def initialize
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["vin"] }.uniq.count
    puts old_offers.count

    CscProviders.cities("dnw").first.all.
      select { |a| a.name =~ /Berlin/ }.
      first.stream_cars do |car|

      offr = old_offers.
        select { |a| a["extdata"]["vin"] == car.vin }.first ||
        (new_offers << JSON(base_data.to_json)).last

      # clone is shallow, use Json to do deep cloning. But it means keys
      # become strings.
      offr.tap do |d|
        p = d["location"]["place"]
        d["text"]                    = BaseText % car.license_plate
        d["validuntil"]              = timestamp + TenMinutesMS
        d["location"]["coordinates"] = [car.location.lng, car.location.lat]
        d["extdata"]                 = { :vin => car.vin }
        d["keywords"] =
          BaseKeyWords + (car.needs_fuelling? ? ["#fuelabledn"] : [])
      end
    end

    send_off(new_offers, old_offers)
  end
end
