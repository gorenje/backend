# coding: utf-8
require 'sidekiq/api'

module BaseImporter

  def self.included(klz)
    klz.class_eval do
      const_set("BaseOffer", {
        :owner         => const_get("Owner"),
        :text          => "",
        :keywords      => const_get("BaseKeyWords"),
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
      })
    end
  end

  def parse_street_and_number(addr)
    if addr =~ /(.+) ([0-9\/\-–]+)$/
      { "route"         => $1.strip,
        "street_number" => $2
      }
    else
      { "route" => addr }
    end
  end

  def parse_address_line(addr)
    if addr =~ /(.+), ([0-9]+) (.+)$/
      {
        "route"                       => $1.strip,
        "postal_code"                 => $2,
        "locality"                    => $3,
        "administrative_area_level_1" => $3,
      }.merge(parse_street_and_number($1.strip))
    else
      { "route" => addr }
    end
  end

  def add_place(subject)
    subject["place"] = {
      "en" => {
        "route"                       => "",
        "street_number"               => "",
        "postal_code"                 => "",
        "locality"                    => "Berlin",
        "administrative_area_level_1" => "Berlin",
        "country"                     => "Germany",
      }
    }
    subject["place"]["en"]
  end

  def timestamp
    @timestamp ||= Time.now.utc.strftime("%s%L").to_i
  end

  def owner
    @owner ||= self.class.const_get("Owner")
  end

  def create_base_data
    JSON(self.class.const_get("BaseOffer").to_json).tap do |d|
      d["validfrom"]  = timestamp
      d["validuntil"] = timestamp + TenMinutesMS
    end
  end

  def get_old_offers_raw
    data = StoreHelper::Agent.new.bulk.offers.send(owner).get
    raise "UnsupportedMismatch: #{data["version"]}" if data["version"] != "1.0"
    data["data"]
  end

  def get_old_offers(&block)
    get_old_offers_raw.map do |offer|
      offer["validuntil"] = timestamp - TwentyFourHoursMS
      offer["keywords"]   = self.class.const_get("BaseKeyWords")
      yield(offer) if block_given?
      offer
    end
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
    TrackerHelper.bulk_update_done(owner)
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

  def delete_all
    StoreHelper::Agent.new.bulk.offers.send(owner).delete
  end
end
