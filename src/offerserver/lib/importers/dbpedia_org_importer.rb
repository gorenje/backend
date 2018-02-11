require_relative '../base_importer'

class DbpediaOrgImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#poi", "#landmark", "#building"].map(&:downcase)
  Owner        = "DbpediaOrg"

  include BaseImporter

  LocationRadius = 500
  UrlTemplate = "http://dbpedia.org/sparql"

  UrlQueries = {
    "default-graph-uri" => "http://dbpedia.org",
    "format" => "application/sparql-results+jsongg",
    "query" =>
    "PREFIX owl: <http://www.w3.org/2002/07/owl#>\n" +
    "PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>\n" +
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n" +
    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
    "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
    "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n" +
    "PREFIX : <http://dbpedia.org/resource/>\n" +
    "PREFIX dbpedia2: <http://dbpedia.org/property/>\n" +
    "PREFIX dbpedia: <http://dbpedia.org/>\n" +
    "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>\n" +
    "\r\n" +
    "PREFIX dbo: <http://dbpedia.org/ontology/>\r\n" +
    "PREFIX n1: <http://schema.org/>\r\n" +
    "PREFIX n4: <http://www.w3.org/2003/01/geo/wgs84_pos#>\r\n" +
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\r\n" +
    "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\r\n" +
    "\r\n" +
    "SELECT DISTINCT ?id ?Place_1 ?Place_long_21 ?Place_lat_22 "+
    "?label ?homepage ?image ?name\r\n" +
    "WHERE { ?Place_1 a dbo:Place  .\r\n" +
    "        ?Place_1 a n1:LandmarksOrHistoricalBuildings .\r\n" +
    "        ?Place_1 n4:lat ?Place_lat_22 .\r\n" +
    "        ?Place_1 n4:long ?Place_long_21 .\r\n" +
    "        ?Place_1 foaf:name ?name .\r\n" +
    "        ?Place_1 dbo:wikiPageID ?id .\r\n" +
    "        OPTIONAL { ?Place_1 foaf:homepage ?homepage . }\r\n" +
    "        OPTIONAL { ?Place_1 foaf:depiction ?image . }\r\n" +
    "        ?Place_1 rdfs:label ?label .\r\n" +
    "        filter langMatches(lang(?label),\"en\") .\r\n" +
    "        filter langMatches(lang(?name),\"en\") .\r\n" +
    "        filter(regex(?name, \"^%s\",\"i\" )) \r\n" +
    "}\r\n"+
    "ORDER BY ?id\r\n"
  }

  def initialize
  end

  def perform(args)
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers_raw

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    args["char"].split(//).each do |char|
      query = JSON(UrlQueries.to_json)
      query["query"] = query["query"] % char

      data = JSON(RestClient.get(UrlTemplate + "?" + query.to_query))
      puts "Found #{data['results']['bindings'].count} for '#{char}'"

      data["results"]["bindings"].each do |dp|
        offer_id = dp["id"]["value"]

        offr =
          old_offers.
            select { |a| a["extdata"]["id"] == offer_id }.first ||
          new_offers.
            select { |a| a["extdata"]["id"] == offer_id }.first ||
          (new_offers << JSON(base_data.to_json)).last

        offr.tap do |d|
          d["validfrom"]               = timestamp.to_i - OneHourMS
          d["validuntil"]              = timestamp.to_i + SevenDaysMS
          d["text"]                    = (dp["label"] || dp["name"])["value"]
          d["location"]["coordinates"] = [dp["Place_long_21"]["value"].to_f,
                                          dp["Place_lat_22"]["value"].to_f]
          d["radiusMeters"]            = LocationRadius
          d["keywords"]                = BaseKeyWords

          if dp["image"] && dp["image"]["value"] && d["images"].nil?
            idstr = ImageHelper.upload_url(dp["image"]["value"])
            d["images"] = [idstr] unless idstr.nil?
          end

          d["extdata"] = {
            "id"   => offer_id,
            "link" => dp["Place_1"]["value"],
          }

          if dp["homepage"] && hp = dp["homepage"]["value"]
            d["extdata"]["homepage"] = hp
          end
        end
      end
    end

    # see berlin_de_kinos_importer why the following is done.
    remove_offers, old_offers =
              old_offers.partition { |offr| offr["validuntil"] < timestamp }
    new_offers = new_offers.select { |offr| offr["validuntil"] > timestamp }

    send_off(new_offers, old_offers, remove_offers)
  end
end
