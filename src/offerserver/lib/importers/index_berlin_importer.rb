class IndexBerlinImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#art"].map(&:downcase)
  Owner        = "IndexBerlin"

  include BaseImporter

  def initialize
  end

  def row_to_open_struct(row)
    venue   = row.search("div[@id='venueName']").first
    attrs   = venue.attributes
    venueid = attrs["venueid"].to_s
    links   = row.search("a")

    artist_website =
      links.select do |a|
      a.text == "Website"
    end.first.attributes["href"].value rescue ""

    index_link = "http://indexberlin.de/?venue&it=%s" % venueid
    addr       = row.search("div[@id='venueAddr']").text.strip.gsub(/\n/,' ')
    telefon    = row.search("div[@id='venueTW']").text.split(/,/).first

    openingtime = row.search("div[@id='venueH']").first.text rescue ""

    return nil if attrs["geolat"].nil? || attrs["geolng"].nil?

    OpenStruct.new({}.tap do |h|
      h["vid"]  = venueid
      h["id"]   = "idxber:%s" % [venueid]
      h["text"] = venue.text
      h["lat"]  = attrs["geolat"].to_s
      h["lng"]  = attrs["geolng"].to_s
      h["keywords"]    = ["##{attrs["venuestatus"].to_s.gsub(/ /,'')}"]
      h["idxberlnk"]   = index_link
      h["route"]       = parse_address_line(addr)
      h["telefon"]     = telefon
      h["website"]     = artist_website
      h["openingtime"] = openingtime
    end)
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

    agent = BaseImporter.mechanize_agent
    agent.get("http://indexberlin.de/#venues").
      search("tr[@class='venuesItem']").
      each do |row|

      entry = row_to_open_struct(row)
      next if entry.nil?

      offr = idmap[entry.id] ||
             new_offers.
               select { |a| a["extdata"]["id"] == entry.id }.first ||
             (new_offers << JSON(base_data.to_json)).last

      offr.tap do |d|
        add_place(d).merge!(entry.route)

        d["text"]                    = entry.text
        d["validuntil"]              = timestamp + TwentyFourHoursMS
        d["location"]["coordinates"] = [entry.lng, entry.lat]
        d["extdata"]                 = { :id  => entry.id,
                                         :vid => entry.vid,
                                         :tel => entry.telefon,
                                         :ilink => entry.idxberlnk,
                                         :elink => entry.website,
                                         :otime => entry.openingtime,
                                       }
        d["keywords"] = BaseKeyWords + entry.keywords
      end
    end

    remove_offers, old_offers =
      old_offers.partition { |offr| offr["validuntil"] < timestamp }

    send_off(new_offers, old_offers, remove_offers)
  end
end
