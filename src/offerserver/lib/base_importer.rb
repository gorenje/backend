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
        :location => {
          :type        => "Point",
          :coordinates => [ 0, 0 ],
          :radius      => 225,
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
      })
    end
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
    StoreHelper::Agent.new.bulk.offers.send(owner).get
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
