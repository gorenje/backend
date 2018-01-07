class BerlinDeImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all"].map(&:downcase)
  Owner        = "BerlinDeDaten"

  include BaseImporter

  BaseUrls = {
    :markt => ("http://www.berlin.de/sen/wirtschaft/service/maerkte-feste/"+
               "wochen-troedelmaerkte/index.php/index/all.json?q="),
  }

  def initialize
  end

  def generate_entries_for_markt
    JSON(RestClient.get(BaseUrls[:markt]))["index"].each do |ety|
      yield markt_hash_to_entry(ety)
    end
  end

  def markt_hash_to_entry(hash)
    hash["id"]       = "markt:#{hash['id']}"
    hash["lat"]      = hash["latitude"].gsub(/,/,  '.').to_f
    hash["lng"]      = hash["longitude"].gsub(/,/, '.').to_f
    hash["title"]    = hash["location"].split(/\n/).first
    hash["keywords"] = hash["location"].downcase.split + ["#markt"]
    OpenStruct.new(hash)
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    BaseUrls.keys.each do |key|
      send("generate_entries_for_#{key}") do |entry|
        offr = old_offers.
          select { |a| a["extdata"]["id"] == entry.id }.first ||
          (new_offers << JSON(base_data.to_json)).last

        offr.tap do |d|
          add_place(d).merge!("route" => entry.location)

          d["text"]                    = entry.title
          d["validuntil"]              = timestamp + TwentyFourHoursMS
          d["location"]["coordinates"] = [entry.lng, entry.lat]
          d["keywords"]                = BaseKeyWords + entry.keywords
          d["extdata"]                 = { :id => entry.id }
        end
      end
    end

    send_off(new_offers, old_offers)
  end
end
