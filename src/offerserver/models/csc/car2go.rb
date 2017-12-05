module Car2Go
  class Car < Car
    def initialize(hsh)
      super(hsh)
      crds = @data["coordinates"]
      @location = Geokit::LatLng.new(crds[1],crds[0])
      @data["fuelType"] = "PE10" # only applies if non-electro
    end

    def is_electro?
      @data["engineType"] == "ED"
    end

    def name
      license_plate
    end

    def needs_fuelling?
      fuel_in_percent <= 10
    end

    def is_charging?
      !!@data["charging"]
    end

    def address_line
      @data["address"]
    end

    def marker_icon
      "/images/marker_car2go_car.svg"
    end

    def vin
      @data["vin"]
    end

    def image_url
      "/images/c2g/#{URI::escape(@data["city_location"])}/#{URI::escape(vin)}"
    end

    def latlng
      [location.lat, location.lng].join(",")
    end

    def reserve_url
      "car2go://car2go.com/vehicle/%s?latlng=%s" % [ vin, latlng ]
    end

    def fuel_in_percent
      @data["fuel"]
    end

    def license_plate
      @data["name"]
    end

    def cleanliness
      @data["interior"] == "GOOD" ? "2/2" : "2/1"
    end
  end

  class City < City
    def self.vehicle_details(loc)
      City.mechanize_agent.
        json("https://www.car2go.com/caba/customer/vehicles/"+
             "#{URI::escape(loc)}?oauth_consumer_key="+
             "#{ENV['CAR2GO_CONSUMER_KEY']}&format=json")["vehicle"]
    end

    def self.image_url_for(loc,vin)
      car_details = vehicle_details(loc).select {|car| car["vin"] == vin}.first

      if car_details.nil?
        "public/images/transparent.png"
      else
        lky = car_details["secondaryColor"] || car_details["primaryColor"]
        clr = Car2GoColorLookup[lky[0..2]]
        age = Car2GoHardwareLookup[car_details["hardwareVersion"]] || ""
        mdl = Car2GoModelLookup[car_details["model"]]
        "public/images/car2go/#{mdl}_#{age}#{clr}.png"
      end
    end

    def self.all
      mechanize_agent.
        json("https://www.car2go.com/api/v2.1/locations?"+
             "oauth_consumer_key=#{ENV['CAR2GO_CONSUMER_KEY']}"+
             "&format=json")["location"].map do |hsh|
        Car2Go::City.new(hsh)
      end
    end

    def initialize(hsh)
      hsh["locationName"] = hsh["id"] if hsh["id"]
      super(hsh)
      loc = @data["mapSection"]["center"] rescue {}
      @location = Geokit::LatLng.new(loc["latitude"], loc["longitude"])
    end

    def name
      "%s, %s" % [ @data["locationName"], @data["countryCode"] ]
    end

    def id
      data["locationName"]
    end

    def stream_cars(&block)
      auth = "?oauth_consumer_key=#{ENV['CAR2GO_CONSUMER_KEY']}&" +
        "format=json&loc=#{CGI::escape(id)}"

      City.mechanize_agent.
        json("https://www.car2go.com/api/v2.1/vehicles" + auth)["placemarks"].
        each do |hsh|
        hsh.merge!("city_location" => id)
        yield(Car2Go::Car.new(hsh))
      end
    end
  end
end

CscProviders.register("ctg", "Car2Go", Car2Go::City)
