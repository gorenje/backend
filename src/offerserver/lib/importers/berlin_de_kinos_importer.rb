# -*- coding: utf-8 -*-
class BerlinDeKinosImporter
  include Sidekiq::Worker

  BaseText     = ""
  BaseKeyWords = ["#all", "#film"].map(&:downcase)
  Owner        = "BerlinDeKinos"

  LocationDimension = {
    "longitudeDelta" => 0.014265495589370403,
    "latitudeDelta" => 0.009410271202277443
  }
  LocationRadius = 1500

  BerlinTimeZone = TZInfo::Timezone.new('Europe/Berlin')

  BaseHost = "https://www.berlin.de"
  BaseUrl  = BaseHost + "/kino/_bin/kinodetail.php/"

  Kinos = {
    30151 => ["Acud Kino", [13.4008652,52.53324628]],
    30152 => ["Adria - Filmtheater", [13.31810788,52.45443478]],
    30154 => ["Kino im Kulturhaus Spandau", [13.202751,52.535472]],
    30155 => ["Kino Arsenal", [13.368002,52.505212]],
    30157 => ["Astra-Filmpalast", [13.50596726,52.44621618]],
    30158 => ["Yorck Kinogruppe - Babylon", [13.41726,52.50023134]],
    30160 => ["Bali-Kino", [13.25904435,52.43207293]],
    30161 => ["Babylon: Mitte", [13.4111516,52.5259332]],
    30162 => ["Blauer Stern", [13.40251236,52.58053581]],
    30166 => ["Bundesplatz-Kino", [13.32929981,52.47898984]],
    30168 => ["Capitol Dahlem", [13.28654032,52.4530506]],
    30169 => ["Casablanca", [13.54663196,52.43650758]],
    30170 => ["Central-Kino", [13.40263727,52.52425594]],
    30172 => ["Neues Cinema", [13.32861531,52.46603475]],
    30173 => ["Cinema Paris", [13.32477578,52.50216163]],
    30174 => ["CineMotion Berlin Hohenschönhausen", [13.50960049,52.5658549]],
    30175 => ["UCI Kinowelt Colosseum", [13.41141,52.54774]],
    30176 => ["CinemaxX Potsdamer Platz", [13.37608273,52.50956216]],
    30177 => ["CineStar Hellersdorf", [13.60440519,52.53736115]],
    30178 => ["CineStar", [13.6059159,52.315092]],
    30180 => ["CineStar im Sony Center", [13.3739878,52.5093112]],
    30181 => ["CineStar Berlin Tegel", [13.28540713,52.58084217]],
    30182 => ["City Wedding", [13.33880351,52.55831881]],
    30183 => ["Cosima-Filmtheater 1", [13.33020668,52.47693587]],
    30184 => ["Delphi Filmpalast am Zoo", [13.32868817,52.50563248]],
    30187 => ["EISZEIT Kino", [13.4335046,52.5002037]],
    30189 => ["Eva-Lichtspiele", [13.31995994,52.48438496]],
    30191 => ["Filmkunst 66", [13.31966867,52.50434416]],
    30192 => ["Astor Film Lounge", [13.33050052,52.50336185]],
    30193 => ["Filmrauschpalast", [13.35847,52.528634] ],
    30195 => ["Filmtheater am Friedrichshain", [13.430667,52.52943142]],
    30197 => ["Freiluftkino Friedrichshain", [13.43619153,52.52521801]],
    30198 => ["Freiluftkino Hasenheide", [13.3989037,52.4853765]],
    30199 => ["Freiluftkino Kreuzberg", [13.4258017,52.5034007]],
    30200 => ["fsk am Oranienplatz", [13.41476966,52.50154917]],
    30201 => ["Toni und Tonino", [13.450836,52.5489923]],
    30202 => ["Yorck & New Yorck", [13.38617153,52.49286617]],
    30203 => ["Hackesche Höfe Kino", [13.40171,52.52478]],
    30205 => ["Freiluftkino Insel im Cassiopeia", [13.45152195,52.50837114]],
    30206 => ["Kino International", [13.4223905,52.5200641]],
    30207 => ["Kino Intimes", [13.4582014,52.5128702]],
    30208 => ["Kant", [13.30845396,52.50676813]],
    30209 => ["Cineplex Neukölln Arcaden", [13.4326361,52.48238431]],
    30211 => ["Kino in der Brotfabrik", [13.430459,52.552604] ],
    30212 => ["Kino Kiste", [13.60875538,52.53550187]],
    30215 => ["Cineplex Spandau", [13.20661379,52.53839958]],
    30217 => ["Klick", [13.29952419,52.50547519]],
    30219 => ["Lichtblick Kino", [13.4025283,52.53870491]],
    30222 => ["Thalia - Movie Magic", [13.344853,52.43463] ],
    30223 => ["Moviemento", [13.42336998,52.4904195]],
    30224 => ["Neues Off", [13.4246771,52.48338044]],
    30226 => ["Kino Krokodil", [13.419321,52.552354]],
    30227 => ["Odeon", [13.34941751,52.48219666]],
    30228 => ["Passage Kinos", [13.43903929,52.47702592]],
    30231 => ["Rollberg Kino", [13.42736486,52.47837292]],
    30235 => ["Tilsiter-Lichtspiele", [13.44742529,52.52047868]],
    30236 => ["Cineplex Titania", [13.32681298,52.46416867]],
    30237 => ["UCI Kinowelt Friedrichshain", [13.44284,52.5245]],
    30238 => ["UCI KINOWELT Gropius Passagen", [13.45673916,52.43049065]],
    30239 => ["UCI KINOWELT Am Eastgate", [13.540994,52.541823]],
    30241 => ["Zoo Palast", [13.33402786,52.50573046]],
    30242 => ["CineStar - Treptower Park", [13.45883969,52.49227135]],
    30245 => ["Cinestar Kino in der Kulturbrauerei", [13.4125461,52.5384522]],
    30246 => ["Xenon", [13.35904637,52.48634891]],
    30247 => ["Zeughauskino des Deutschen Historischen Museums Berlin",
              [13.39705776,52.51778946]],
    31295 => ["Filmpalast", [13.2370575,52.7499456]],
    31345 => ["Filmmuseum", [13.0559503,52.3952015]],
    31347 => ["Thalia Arthouse-Kino Babelsberg", [13.0953996,52.3917533]],
    31348 => ["UCI KINOWELT Potsdam", [13.06528595,52.3934182]],
    31975 => ["Kino Sputnik Südstern", [13.40967208,52.48895776]],
    32139 => ["CineStar Berlin – CUBIX am Alexanderplatz", [13.37842,52.4514]],
    33998 => ["Freiluftkino Friedrichshagen", [13.6189037,52.45871876]],
    34000 => ["ARTE Sommerkino Kulturforum", [13.3681941,52.5085781]],
    34187 => ["Alhambra", [13.35984321,52.54417738]],
    34286 => ["Filmrauschpalast", [13.3591731,52.5342385]],
    34313 => ["Kino Spreehöfe", [13.50999176,52.46312462]],
    34516 => ["Freilichtbühne Weißensee", [13.45542,52.556609] ],
    34524 => ["Union Filmtheater Friedrichshagen", [13.62550296,52.45626961]],
    34687 => ["Autokino Berlin Schönefeld", [13.467553,52.35625] ],
    34990 => ["Open Air Kino Mitte", [13.401842,52.51696] ],
    35211 => ["b-ware! Ladenkino", [13.4615156,52.5119038]],
    35284 => ["Freiluftkino Spandau", [13.2010102,52.5361091]],
    35299 => ["Literaturhaus Berlin", [13.326721,52.49848] ],
    35529 => ["Freiluftkino Rehberge", [13.330278,52.550272]],
    35589 => ["Bärliner Autokino", [13.30546,52.5534076]],
    35898 => ["CineStar Imax 3D", [13.374368,52.5096088]],
    35920 => ["Freifluftkino Pompeji", [13.4660142,52.5013341]],
    35972 => ["Zukunft", [13.4666,52.5013]],
    36254 => ["Sommerkino am Kranzler Eck", [13.3308556,52.5041854]],
    36435 => ["Nomadenkino Berlin", [13.3246134,52.4993282]],
    36448 => ["Il Kino", [13.429676,52.488245] ],
    36491 => ["B-ware! Open Air FMP1", [13.440739,52.513117] ],
    36504 => ["Sommerkino am Bundespresseamt", [13.3837024,52.5185727]],
    36522 => ["B-ware! Open Air Prinzessinnengärten", [13.4115,52.501301] ],
    36588 => ["Freiluftkino im Körnerpark", [13.441,52.47239]],
    36676 => ["Wolf", [13.433907,52.483396] ],
    36814 => ["WBB Kinogarten", [13.411927,52.554895] ],
    36947 => ["B-ware! Open Air Gärten Gut Hellersdorf",
               [13.558169,52.544168] ],
  }

  include BaseImporter

  def initialize
  end

  # assumption date is of the format 27.08.17 and time is of 20:00 format.
  def convert_to_utc(date, time)
    magic_format_string = "%d.%m.%y %H:%M"

    # first determine which timezone is valid on a specific berlin time:
    dtobj  = DateTime.strptime("#{date} #{time}", magic_format_string)
    period = BerlinTimeZone.period_for_local(dtobj)
    abbr   = period.abbreviation

    # now using the timezone, convert berlin time to UTC
    DateTime.strptime(dtobj.strftime(magic_format_string) + " #{abbr}",
                      magic_format_string + " %Z").to_time.utc
  end

  def perform
    base_data  = create_base_data
    new_offers = []
    old_offers = get_old_offers_raw

    puts old_offers.map { |a| a["extdata"]["id"] }.uniq.count
    puts old_offers.count

    agent = City.mechanize_agent

    Kinos.each do |kinoid, (kinoname, kinoloc)|
      page = begin
               agent.get(BaseUrl + kinoid.to_s)
             rescue Exception => e
               puts e.message
               next
             end

      address = page.search("span[@class=street-address]").text rescue ""
      kino_proper_name =
        page.search("div.bo_mainbar h1[@class=top]").text rescue kinoname

      page.search("div#kino_accordeon > div").each_slice(2) do |name, program|
        filmname = name.search("a").text

        filmurl =
          BaseHost + program.search("tr td[colspan='2']").search("a").
          attribute("href").value

        program.search("tr > td.datum").each do |td|
          parent = td.parent
          datestr = parent.search("td.datum").text.split(/,/).last.strip

          parent.search("td.uhrzeit").text.split(/,/).map(&:strip).
            each do |timestr|
            utctime = convert_to_utc(datestr, timestr)

            # each showing becomes one entry in the database, for reasons
            # of validation --> showings become automagically invalid after
            # they have started.
            entry_id = [filmurl, kinoid.to_s,
                        utctime.strftime("%s%L")].join("|")

            offr =
              old_offers.
              select { |a| a["extdata"]["id"] == entry_id }.first ||
              new_offers.
              select { |a| a["extdata"]["id"] == entry_id }.first ||
              (new_offers << JSON(base_data.to_json)).last

            offr.tap do |d|
              p = d["location"]["place"]
              p["en"]["route"]             =
                "%s (%s)" % [address,kino_proper_name]
              d["validfrom"]               =
                utctime.strftime("%s%L").to_i - TwoHoursMS
              d["text"]                    = filmname
              d["validuntil"]              = utctime.strftime("%s%L").to_i
              d["location"]["coordinates"] = kinoloc
              d["location"]["dimension"]   = LocationDimension
              d["location"]["radius"]      = LocationRadius
              d["keywords"]                = BaseKeyWords + [filmname.downcase]
              d["extdata"]                 = {
                "id"          => entry_id,
                "berlin_time" => "#{datestr}, #{timestr}"
              }
            end
          end
        end
      end
    end

    # go through the old_offers and remove the offers, i.e. screenings, that
    # have expired, i.e. were shown in the past. No need to keep these
    # offers, just taking up space in the database.
    # In a second step, because these old_offers will be re-added as new
    # offers (when this gets executed again) need to filter the new_offers
    # to remove films that were shown in the past.
    remove_offers, old_offers =
      old_offers.partition { |offr| offr["validuntil"] < timestamp }
    new_offers = new_offers.select { |offr| offr["validuntil"] > timestamp }

    send_off(new_offers, old_offers, remove_offers)
  end
end
