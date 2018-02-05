module GeoHelper
  extend self

  def lookup(street, house_num, postcode, city)
    query_str = "#{street} #{house_num}, #{postcode} #{city}"

    JSON(BaseImporter.
           mechanize_agent.get("https://pelias.lokaler.de/v1/search?"+
                               "text=#{CGI.escape(query_str)}").body)
  end
end
