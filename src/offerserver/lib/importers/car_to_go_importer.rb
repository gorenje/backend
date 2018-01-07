class CarToGoImporter
  include Sidekiq::Worker

  BaseText     = "CarSharing Car2Go %s"
  BaseKeyWords = ["CarSharing", "Car2Go", "#car", "#all"].map(&:downcase)
  Owner        = "Car2goCarSharing"

  include BaseImporter

  def initialize
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["vin"] }.uniq.count
    puts old_offers.count

    CscProviders.cities("ctg").first.all.
      select { |a| a.name =~ /Berlin/ }.
      first.stream_cars do |car|

      offr = old_offers.
        select { |a| a["extdata"]["vin"] == car.vin }.first ||
        (new_offers << JSON(base_data.to_json)).last

      offr.tap do |d|
        add_place(d).merge!(parse_address_line(car.address_line))
        d["text"]                    = BaseText % car.license_plate
        d["validuntil"]              = timestamp + TenMinutesMS
        d["location"]["coordinates"] = [car.location.lng, car.location.lat]
        d["extdata"]                 = { :vin => car.vin }
        d["keywords"] =
          BaseKeyWords + (car.needs_fuelling? ? ["#fuelablec2g"] : [])
      end
    end

    send_off(new_offers, old_offers)
  end
end
