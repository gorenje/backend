# coding: utf-8
class BerlinNaturImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#natur"].map(&:downcase)
  Owner        = "BerlinDeNatur"

  include BaseImporter

  BaseUrls = {
    :baeume => ("http://www.berlin.de/ba-charlottenburg-wilmersdorf/"+
                "verwaltung/aemter/umwelt-und-naturschutzamt/naturschutz/"+
                "baeume/index.php/index/all.json?q="),
    :findlinge => ("http://www.berlin.de/ba-charlottenburg-wilmersdorf/"+
                   "verwaltung/aemter/umwelt-und-naturschutzamt/naturschutz"+
                   "/findlinge/index.php/index/all.json?q="),
  }

  def initialize
  end

  def generate_entries_for_findlinge
    JSON(RestClient.get(BaseUrls[:findlinge]))["index"].each do |hsh|
      yield findlinge_hash_to_entry(hsh)
    end
  end

  def generate_entries_for_baeume
    JSON(RestClient.get(BaseUrls[:baeume]))["index"].each do |hsh|
      yield baeume_hash_to_entry(hsh)
    end
  end

  def baeume_hash_to_entry(hsh)
    hsh["id"]        = "baeume:#{hsh['id']}"
    hsh["lng"]       = hsh["laengengrad"].gsub(/,/,  '.').to_f
    hsh["lat"]       = hsh["breitengrad"].gsub(/,/,  '.').to_f
    hsh["location"]  = hsh["adresse"]
    hsh["keywords"]  = ["#baeume"]
    hsh["title"]     = hsh["dt_name"]
    hsh["image_url"] = hsh["original_bild"].gsub(/^.Foto.:/, '')
    OpenStruct.new(hsh)
  end

  def findlinge_hash_to_entry(hsh)
    hsh["id"]        = "findlinge:#{hsh['id']}"
    hsh["lng"]       = hsh["laengengrad"].gsub(/,/,  '.').to_f
    hsh["lat"]       = hsh["breitengrad"].gsub(/,/,  '.').to_f
    hsh["location"]  = hsh["adresse"]
    hsh["keywords"]  = ["#findlinge"]
    hsh["title"]     = "Findling - #{hsh['standort']}"
    hsh["image_url"] = hsh["original_bild"].gsub(/^.Foto.:/, '')
    OpenStruct.new(hsh)
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
          add_place(d).merge!(parse_street_and_number(entry.location))

          d["text"]                    = entry.title
          d["validuntil"]              = timestamp + TwentyFourHoursMS
          d["location"]["coordinates"] = [entry.lng, entry.lat]
          d["keywords"]                = BaseKeyWords + entry.keywords
          d["extdata"]                 = { :id => entry.id }

          if entry.image_url && d["images"].nil?
            d["images"] = [ImageHelper.upload_url(entry.image_url)]
          end
        end
      end
    end

    puts new_offers.count
    send_off(new_offers, old_offers)
  end
end
