# -*- coding: utf-8 -*-
module ChatbotTestHelper
  extend self

  TestOffer = {
    "_id"=>"1234testing1234",
    "__v"=>0,
    "owner"=>"BerlinDeKinos",
    "text"=>"Lucky Loser - Ein Sommer in der Bredouille (DFmenglU)",
    "validfrom"=>1502606285668,
    "validuntil"=>1503654163328,
    "image"=>[],
    "extdata"=>{
      "id"=>"https://www.berlin.de/kino/_bin/filmdetail.php/244492|30151|1504120500000",
      "berlin_time" => "28.08.17 20:00"},
    "images"=>[],
    "trusted"=>true,
    "modified"=>1502564005100,
    "created"=>1502564005100,
    "isMobile"=>false,
    "allowContacts"=>true,
    "showLocation"=>true,
    "location"=> {
      "place"=>{
        "en"=>{"locality"=>"Berlin", "country"=>"Germany",
          "route"=>"Ueckermünder Str. 7, 10439 Berlin"}},
      "dimension"=>{"longitudeDelta"=>0.0017342150719485971,
        "latitudeDelta"=>0.0017342150719485971},
      "coordinates"=>[13.40021, 52.5528],
      "type"=>"Point"
    },
    "keywords"=>[],
    "rank"=>0,
    "isKeyword"=>[]
  }

  def create_event(msg = "fubar")
    Consumers::Kafka::ChatbotEvent.
      new("/chm bot_name&country=US&device=desktop&device_name&ip=916624154"+
          "&klag=1&platform=gnu%2Flinux&ts=1503653433 churl=sendbird_group_"+
          "channel_35839981_63b925b65c080ea25c64bf44d668b471ac1f123b&chnam="+
          "598ff3d1e9679600128168a0_undefined&snder=3e378e9b176c917e&mbers="+
          "3e378e9b176c917e&mbers=BerlinDeKinos&msg=#{msg}")
  end

end
