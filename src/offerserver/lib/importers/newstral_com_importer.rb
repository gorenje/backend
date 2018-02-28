class NewstralComImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#news"].map(&:downcase)
  Owner        = "NewstralCom"

  include BaseImporter

  LocationRadius = 225
  BaseUrl        = "https://newstral.com"
  CentroidRegExp = /\((-?[0-9\.]+),(-?[0-9\.]+)\)/

  def initialize
  end

  def perform(args)
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers_raw

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    JSON(RestClient.get(BaseUrl+"/#{args["cc"]}/maps/clusters").body).
      each do |(cluster_loc,cnt,datetime)|

      url = BaseUrl+"/#{args["cc"]}/maps/news-for-point?centroid=#{cluster_loc}"
      puts "Dealing with #{cluster_loc} / #{cnt}"

      headlines(JSON(RestClient.get(url))).each do |headline|
        begin
          doc = Nokogiri::HTML(headline)

          offer_id = doc.xpath("//li[@*['data-headline-id']]").first.
                       attribute("data-headline-id").value
          logo     = doc.xpath("//a[@class='source-logo']").
                       search("img").first.attribute("src").value rescue nil

          details = doc.xpath("//div[@class='title']").search("a")
          text    = details.text.gsub(/[[:space:]]+/,' ')
          link    = details.attribute("href").value

          datestamp = (doc.xpath("//time[@class='discovery-timestamp']").
                         attribute("data-timestamp").
                         value.to_i * 1000) rescue timestamp

          location = doc.search("span.locations").search("span.location").
                       first.attribute("data-centroid").
                       value rescue cluster_loc

          [lat = $1.to_f, lng = $2.to_f] if location =~ CentroidRegExp

          next if lat.nil? || lng.nil?

          offr =
            old_offers.select { |a| a["extdata"]["id"] == offer_id }.first ||
            new_offers.select { |a| a["extdata"]["id"] == offer_id }.first ||
            (new_offers << JSON(base_data.to_json)).last

          offr.tap do |d|
            d["validfrom"]               = datestamp
            d["validuntil"]              = datestamp + TwelveHoursMS
            d["text"]                    = text
            d["location"]["coordinates"] = [lng, lat]
            d["radiusMeters"]            = LocationRadius
            d["keywords"]                = BaseKeyWords

            d["extdata"] = {
              "id"   => offer_id,
              "link" => link
            }

            if logo && d["images"].nil?
              idstr = ImageHelper.upload_url(BaseUrl + logo) rescue nil
              d["images"] = [idstr] unless idstr.nil?
            end
          end
        rescue Exception => e
          puts e
          next
        end
      end
    end

    # see berlin_de_kinos_importer why the following is done.
    remove_offers, old_offers =
              old_offers.partition { |offr| offr["validuntil"] < timestamp }
    new_offers = new_offers.select { |offr| offr["validuntil"] > timestamp }

    send_off(new_offers, old_offers, remove_offers)
  end

  private

  def headlines(data)
    ((data[data.keys.first] || {})["headlines"] || [])
  end
end
