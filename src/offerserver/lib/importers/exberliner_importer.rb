class ExberlinerImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#location", "#all"].map(&:downcase)
  Owner        = "ExBerlinerLocations"

  BaseUrl = "http://www.exberliner.com/api/search/location/"+
    "business-and-location-directory/get_search_results?"+
    "search_value=&letter_filter=all&categories=&ord=alpha&page=%d"

  include BaseImporter

  def initialize
  end

  def extract_from_html(html)
    elems = Nokogiri::HTML(html)
    {
      "address" => (elems.xpath("//div[@class='address']/p").children.
                    first.content),
      "keywords" => (elems.xpath("//p[@class='feats']").children.
                     map { |a| a.content.downcase.split(/,/).map(&:strip) }.
                     flatten),
      "id" => elems.xpath("//a").first.attributes["href"].value,
      "desc" => (elems.xpath("//div[@class='details']/p[@class='description']").
                 first.content)
    }.tap do |hsh|
      hsh["route"] = parse_address_line(hsh["address"])
    end
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    page_number = 1
    while true
      puts "Scanning page #{page_number}"

      data = JSON(RestClient.get(BaseUrl % page_number))
      data["results"].each do |entry|
        entry = OpenStruct.new(entry.merge(extract_from_html(entry["html"])))

        offr = old_offers.
          select { |a| a["extdata"]["id"] == entry.id }.first ||
          (new_offers << JSON(base_data.to_json)).last

        # clone is shallow, use Json to do deep cloning. But it means keys
        # become strings.
        offr.tap do |d|
          add_place(d).merge!(entry.route)

          d["text"]                    = entry.title
          d["validuntil"]              = timestamp + TwentyFourHoursMS
          d["location"]["coordinates"] = [entry.lng, entry.lat]
          d["keywords"]                = BaseKeyWords + entry.keywords
          d["extdata"]                 = {
            :id   => entry.id,
            :desc => entry.desc
          }
        end
      end

      data["more"] ? page_number += 1 : break
    end

    send_off(new_offers, old_offers)
  end
end
