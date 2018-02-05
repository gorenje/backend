class AbandonedBerlinImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#abandonedplace", "#abandonedplaces", "#all"].map(&:downcase)
  Owner        = "AbandonedBerlin"

  BaseDataUrl = ("http://www.abandonedberlin.com/feeds/posts/"+
                 "default?max-results=500&alt=json")

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
    page = agent.get(BaseDataUrl)

    data = JSON(page.body)

    data["feed"]["entry"].each do |entry|
      elems = Nokogiri::HTML(entry["content"]["$t"])

      d = elems.xpath("//a").select do |a|
        v = a.attributes["href"].try(:value)
        v =~ /google/ && v =~ /maps/
      end.each do |a|
        a.attributes["href"].value
      end

      if d.count > 0
        lng, lat = [0,0]
        uri = URI.parse(d.first["href"])

        if uri.query
          data = CGI.parse(URI.parse(d.first["href"]).query)
          if data.keys.include?("ll")
            lat, lng = data["ll"].first.split(",")
          elsif uri.path =~ /@(.+),(.+),/
            lat, lng = [$1,$2]
          elsif data.keys.include?("q")
            lat, lng = data["q"].first.split(",")
          else
            puts "============================"
            puts "***** Not handling:"
            puts d.first["href"]
            puts data
            next
          end
        elsif uri.path =~ /@(.+),(.+),/
          lat, lng = [$1,$2]
        else
          puts "============================"
          puts "********* Unable to handle."
          puts d.first["href"]
          next
        end

        title = entry["title"]["$t"]
        id =  entry["link"].select { |a| a["rel"] == "alternate"}.first["href"]

        offr = old_offers.
          select { |a| a["extdata"]["id"] == id }.first ||
          (new_offers << JSON(base_data.to_json)).last

        offr.tap do |d|
          d["text"]                    = title
          d["validuntil"]              = timestamp + TwentyFourHoursMS
          d["location"]["coordinates"] = [lng.to_f, lat.to_f]
          d["keywords"]                = BaseKeyWords + title.downcase.split
          d["extdata"]                 = { :id => id }
        end
      end
    end

    send_off(new_offers, old_offers)
  end
end
