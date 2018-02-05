class UrbaniteNetImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all"].map(&:downcase)
  Owner        = "UrbaniteNet"

  BaseHost = "http://www.urbanite.net"
  BasePath = BaseHost + "/de/berlin/locations/kategorie"

  AllPages = {
    :museen          => BasePath + "/museen-galerien/",
    :kinos           => BasePath + "/kino-videotheken/",
    :theater         => BasePath + "/theater-musik/",
    :kulturlocations => BasePath + "/kultureinrichtungen-veranstaltungsorte/",
    :openairkinos    => BasePath + "/open-air-kinos/"
  }

  ExtraKeywords = {
    :museen          => [],
    :kinos           => ["#kino"],
    :theater         => [],
    :kulturlocations => ["#kultureinrichtung"],
    :openairkinos    => ["#kino", "#kinos"]
  }

  include BaseImporter

  def initialize
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    agent = BaseImporter.mechanize_agent

    AllPages.each do |keyword, urlstr|
      page = agent.get(urlstr)

      page.search("li.item").each do |item|
        link = item.search("h2[data-sort='name'] a")
        details_page = agent.click(link.first)

        begin
          hsh = {
            :lat => (details_page.
                     search("head meta[property='place:location:latitude']").
                     attribute("content").value),

            :lng => (details_page.
                     search("head meta[property='place:location:longitude']").
                     attribute("content").value),

            :id =>
            (details_page.search("head link").
             select {|a| a.attribute("rel").try(:value) == "canonical"}.
             first.attribute("href").value),

            :image_url =>
            (details_page.search("head meta[property='og:image']").
             attribute("content").value rescue nil),

            :external_link =>
            (details_page.search("ul.quickinfo li").
             select { |a| a.search("strong").first.try(:content) == "Web" }.
             first.search("a").attribute("href").value rescue nil),


            :keywords => (details_page.search("head meta[name='keywords']").
                          attribute("content").value rescue ""),

            :long_title => details_page.search("head title").text.try(:strip),

            :address => item.search("div.info div").text.try(:strip),

            :title => link.text.try(:strip)
          }

          entry = OpenStruct.new(hsh)

          entry.keywords = entry.keywords.split(/,/).map do |word|
            word.downcase.strip
          end + ["##{keyword}"] + ExtraKeywords[keyword]

          offr = old_offers.
            select { |a| a["extdata"]["id"] == entry.id }.first ||
            new_offers.
            select { |a| a["extdata"]["id"] == entry.id }.first ||
            (new_offers << JSON(base_data.to_json)).last

          offr.tap do |d|
            add_place(d).merge!("route" => entry.address)

            d["text"]                    = entry.title
            d["validuntil"]              = timestamp + TwentyFourHoursMS
            d["location"]["coordinates"] = [entry.lng, entry.lat]
            d["keywords"]                = BaseKeyWords + entry.keywords
            d["extdata"]                 = {
              "id"         => entry.id,
              "link"       => entry.external_link,
              "long_title" => entry.long_title
            }

            begin
              if entry.image_url && d["images"].nil?
                d["images"] = [ImageHelper.upload_url(entry.image_url)]
              end
            rescue Exception => e
            end
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace
          nil
        end
      end
    end

    send_off(new_offers, old_offers)
  end
end
