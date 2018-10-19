# Offer Server

Generate offers in bulk from various sources. The intention is to have
a base of offers that are available for new users. These offers are basically
anything that has geo location data and might be of interest for someone
using this product.

All importers are managed by [Sidekiq](https://sidekiq.org) (as cron jobs)
and run at [various times](config/initializers/sidekiq.rb#L8-L102).

Currently the following services are supported:

- [abandonedverlin.com](https://www.abandonedberlin.com/) which has a
  wonderful list of abandoned places in and around Berlin.
  [Importer](lib/importers/abandoned_berlin_importer.rb).

- [berlin.de](https://www.berlin.de/sen/web/service/maerkte-feste/wochen-troedelmaerkte/)
  which imports the location of various flea markets in and around Berlin.
  [Importer](lib/importers/berlin_de_importer.rb).

- [berlin.de](https://www.berlin.de/kino/_bin/index.php) also has a
  list of all cinemas and their programs. These are imported and their
  programs updated regularly.
  [Importer](lib/importers/berlin_de_kinos_importer.rb)

- [dbpedia.org](https://wiki.dbpedia.org/) which is like wikipedia but
  with geo locations and [Sparql](https://en.wikipedia.org/wiki/SPARQL)
  query language. [Importer](lib/importers/dbpedia_org_importer.rb).

- [exberliner.com](http://www.exberliner.com/) which has a nice list of
  various restaurants and bars in and around Berlin.
  [Importer](lib/importers/exberliner_importer.rb).

- [indexberlin.de](http://indexberlin.de/) which provides lists of galleries
  and upcoming events in those galleries.
  [Importer](lib/importers/index_berlin_importer.rb).

- [luftdaten.de](https://luftdaten.info/) is a project to collect air
  quality data from around the world. They also have a nice
  [json](http://api.luftdaten.info/static/v2/data.json) dataset with
  everything needed.
  [Importer](lib/importers/luft_daten_importer.rb).

- [meetup.com](https://www.meetup.com/) which can be searched for Berlin
  to find upcoming meetups. Again, data is imported with time and location
  so that only upcoming meetups are in the database.
  [Importer](lib/importers/meetup_importer.rb).

- [newstral.com](https://newstral.com/) has location based news from various
  online newsportals.
  [Importer](lib/importers/newstral_com_importer.rb).
