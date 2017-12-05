class BerlinTheaterImporter
  def philharmoniker_berlin
    # HTML pages with <article>....</article> for each concert
    urlstr =
      "https://www.berliner-philharmoniker.de/konzerte/kalender/von/2017-08/"
    tickets = "https://www.berliner-philharmoniker.de/api/tickets/" # JSON
  end

  def gorki_berlin
    url = "http://www.gorki.de/de/calendar/season/ics"
    [Icalendar::Calendar.parse(RestClient.get(url))].flatten.
      each do |calendar|
      calendar.events.each do |event|
        puts "="*30
        puts event.dtstart
        puts event.dtstart.utc.strftime("%s%L")
        puts event.dtend
        puts event.uid
        puts event.url
        puts event.location
        puts event.summary
        puts event.description
      end
    end
  end

  def deutsche_oper
    url_base =
      "https://www.deutscheoperberlin.de/de_DE/ical/meineoper.ics?date="

    # Here '+1' represents, because it's a date, one day.
    [Date.today.beginning_of_month, # this month
     Date.today.end_of_month + 1, # next month
     (Date.today.end_of_month + 1).end_of_month + 1 # next, next month
    ].map { |d|d.strftime("%d-%m-%Y")}.each do |datestr|
      url = url_base + datestr
      [Icalendar::Calendar.parse(RestClient.get(url))].flatten.
        each do |calendar|
        calendar.events.each do |event|
          puts "="*30
          puts event.dtstart
          puts event.dtstart.utc.strftime("%s%L")
          puts event.dtend
          puts event.uid
          puts event.url
          puts event.location
          puts event.summary
          puts event.description
        end
      end
    end
  end

  KomischeOperBaseHost = "https://www.komische-oper-berlin.de"
  def komische_oper
    urlstr = KomischeOperBaseHost +
      "/callbacks/getschedule.json?filter=&displaymode="

    document = Nokogiri::HTML(JSON(RestClient.get(urlstr))["Schedule"])

    document.xpath("//a[@class='schedule-performance-functions-ical']").
      map { |a| KomischeOperBaseHost + a.attribute("href").value }.each do |url|
      [Icalendar::Calendar.parse(RestClient.get(url))].flatten.
        each do |calendar|
        calendar.events.each do |event|
          puts "="*30
          puts event.dtstart
          puts event.dtstart.utc.strftime("%s%L")
          puts event.dtend
          puts event.uid
          puts event.url
          puts event.summary
          puts event.location
          puts event.description
        end
      end
    end
  end

  def initialize
  end
end
