class MeetupImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#meetup"].map(&:downcase)
  Owner        = "MeetupCom"

  include BaseImporter

  LocationRadius = 1500
  BaseUrl        = "https://www.meetup.com/find/"

  def initialize
  end

  def perform(args)
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers_raw

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    agent = BaseImporter.mechanize_agent

    params = {
      :pageToken    => "default|0",
      :allMeetups   => "true",
      :keywords     => "",
      :radius       => "50",
      :userFreeform => "Berlin, Germany",
      :mcId         => "c1007698",
      :mcName       => "Berlin, DE",
      :sort         => "default",
      :__fragment   => "simple_search",
      :op           => ""
    }

    (args["start"]...args["end"]).step(100).each do |page_num|
      puts "Handling page: #{page_num}"

      params[:pageToken] = "default|#{page_num}"
      ary  = JSON(agent.get(BaseUrl + "?" + URI.encode_www_form(params)).body)
      html = ary.first.gsub(/[[:space:]]+/, " ")

      Nokogiri::HTML(html).search("li.groupCard").each do |groupcard|
        group_name = groupcard.attribute("data-name").try(:value)
        group_id   = groupcard.attribute("data-chapterid").try(:value)
        group_url  = groupcard.search("a").first.attribute("href").try(:value)
        foto       = groupcard.search("a.groupCard--photo").
                       attribute("style").try(:value)

        next if group_name.nil? || group_id.nil? || group_url.nil?

        group_foto = $1 if foto =~ /url\((.+)\)/
        page       = agent.get(group_url) rescue next

        attend_link = page.links.select { |a| a.text == "Attend" }.first

        next if attend_link.nil?

        page = attend_link.click rescue next

        meetup_id = page.uri.to_s
        meta_tags = page.search("meta")
        pos       = property_from(meta_tags, "geo.position")
        img       = property_from(meta_tags, "og:image")
        title     = property_from(meta_tags, "og:title")
        keywords  = name_from(meta_tags, "keywords").try(:split,",")

        # value is in millisecond
        datetime = page.search("div.eventTimeDisplay").
                     try(:search,"time").try(:first).
                     try(:attribute, "datetime").try(:value)

        next if datetime.nil? || pos.nil? || title.nil?

        offr =
          old_offers.
            select { |a| a["extdata"]["id"] == meetup_id }.first ||
          new_offers.
            select { |a| a["extdata"]["id"] == meetup_id }.first ||
          (new_offers << JSON(base_data.to_json)).last

        offr.tap do |d|
          d["validfrom"]               = datetime.to_i - FourtyEightHoursMS
          d["validuntil"]              = datetime.to_i + OneHourMS
          d["text"]                    = title
          d["location"]["coordinates"] = pos.split(";").map(&:to_f).reverse
          d["radiusMeters"]            = LocationRadius
          d["keywords"]                = BaseKeyWords +
                                         (keywords ? keywords : []).
                                           map(&:downcase)
          if img && d["images"].nil?
            idstr = ImageHelper.upload_url(img)
            d["images"] = [idstr] unless idstr.nil?
          end

          d["extdata"] = {
            "id"          => meetup_id,
            "berlin_time" => to_berlin_time(datetime),
            "group_name"  => group_name,
            "group_url"   => group_url,
            "group_id"    => group_id,
          }
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

  def to_berlin_time(datetime_ms)
    dtobj = DateTime.strptime( (datetime_ms.to_i/1000).to_s, "%s" )
    BerlinTimeZone.utc_to_local(dtobj).strftime("At %H:%M on %d. %b, %Y")
  end

  def property_from(meta_tags, name)
    meta_tags.select do |a|
      a.attribute("property").try(:value) == name
    end.first.try(:attribute,"content").try(:value)
  end

  def name_from(meta_tags, name)
    meta_tags.select do |a|
      a.attribute("name").try(:value) == name
    end.first.try(:attribute,"content").try(:value)
  end
end
