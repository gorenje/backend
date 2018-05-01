# coding: utf-8
['sinatra','haml','thin','rest-client','yaml'].map { |a| require(a) }

namespace :webapp do
  desc "Run a simple webserver on top of google sphere images"
  task(:pano) { Thin::Server.new(3001).tap { |s| s.app = PanoApp }.start }
end

class PanoApp < Sinatra::Base
  enable :inline_templates
  set :show_exceptions, :after_handler

  Header = {
    :content_type => "application/json",
    :accept       => "application/json"
  }
  Failed = OpenStruct.new(:code => 500)

  RegExp = /@([-?[:digit:]\.]+),([-?[:digit:]\.]+).+,([-?[:digit:]\.]+)y.*,([-?[:digit:]\.]+)h.*,([-?[:digit:]\.]+)t.+\!1s(.+)\!2e/

  def link_to_hash(objid,link)
    if link =~ RegExp
      panoid = $6.length == 22 ? $6 : "F:#{CGI.escape($6)}"
      { :link  => link,
        :id    => panoid,
        :objid => objid,
        :location => {
          :lat => $1.to_f,
          :lng => $2.to_f
        },
        :pov => {
          :heading => $4.to_f,
          :pitch   => $5.to_f - 90
        },
        :zoom => 0
      }
    else
      nil
    end
  end

  get '/export' do
    content_type :text
    u,p = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
    data = JSON(RestClient.get("https://#{u}:#{p}@store.staging.pushtech.de"+
                               "/offers?owner=GoogleAlbum"))["data"].
             select { |a| a["text"] =~ /looking straight at the sun/i }

    { :date => DateTime.now.to_s,
      :data => data.
                 map { |a| [a["_id"],a["extdata"]["link"]] }.
                 sort_by { |a,_| a }.
                 map { |objid,link| link_to_hash(objid,link) }.compact
    }.to_json
  end

  get '/duplicates' do
    u,p = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
    data = JSON(RestClient.get("https://#{u}:#{p}@store.staging.pushtech.de"+
                               "/offers?owner=GoogleAlbum"))["data"].
             select { |a| a["text"] =~ /looking straight at the sun/i }

    @dups = data.map { |a| [a["_id"],a["extdata"]["link"]] }.
              group_by do |(_,link)|
                link =~ RegExp
                $6
              end.to_a.select { |(_,b)| b.size > 1 }

    haml :duplicates, :layout => false
  end

  get '/image' do
    content_type :json
    data = JSON(RestClient.
                  get("https://gist.githubusercontent.com"+
                      "/gorenje/4086f765cde6236f06c4fde0a67e2dd3/raw").body)

    data["data"].reject { |a| a["objid"] == params[:l] }.sample.to_json
  end

  get '/add' do
    link = params[:l]
    halt(404) if (link =~ /@([-?[:digit:]\.]+),([-?[:digit:]\.]+)/).nil?
    lat,lng = [$1,$2].map(&:to_f)

    hsh = {
      :owner         => "GoogleAlbum",
      :text          => "Looking straight at the Sun",
      :keywords      => ["#all", "#googlealbum"],
      :validfrom     => Time.now.utc.strftime("%s%L").to_i,
      :validuntil    => (Date.today + 1000).to_time.utc.strftime("%s%L").to_i,
      :isMobile      => false,
      :allowContacts => true,
      :showLocation  => true,
      :images        => [],
      :extdata       => { :link => link },
      :radiusMeters  => 500,
      :location => {
        :type        => "Point",
        :coordinates => [ lng, lat ],
      }
    }

    u,p = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
    r = RestClient.
          post("https://#{u}:#{p}@store.staging.pushtech.de/offers",
               hsh.to_json, Header) rescue Failed

    halt(r.code)
  end

  get '/pano(/:id)?' do
    haml :pano, :layout => false
  end
end

__END__

@@ duplicates
!!!
%html
  %head
  %body
    %h1 The Higher The 'Y' Value, The Better
    %table
      %tbody
        - @dups.to_a.each do |(id,hshs)|
          %tr
            %td{ :colspan => 2 }= id
          - hshs.each do |(objid, link)|
            %tr
              %td
                %a{:href => "https://store.staging.pushtech.de/store/details/#{objid}"}= objid
              %td
                %a{:href => link, :target => "_blank" }= link

@@ pano
!!!
%html
  %head
    %script{:src => "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"}
    %script{:src => "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js"}
    %meta{:charset => "utf-8"}/
    %title Sun Traveller
    :css
      html, body {
        height: 100%;
        margin: 0;
        padding: 0;
      }
      #map, #pano {
        float: left;
        height: 93%;
        width: 50%;
      }
  %body
    #operations
      %button{ :onclick => "nextLocation();" } Next Sun
      %button#createsun{ :onclick => "createSun();" } Create Sun
      %a#details{ :href => "", :target => "_blank" } Details
      %a{ :href => "/duplicates", :target => "_blank" } Duplicates
      %a{ :href => "/export", :target => "_blank" } Export
      %a{ :href => "https://gist.github.com/gorenje/038a6a617f6501921bcc8be9d2046386", :target => "_blank" } Gist
      %a{ :href => "https://gist.github.com/gorenje/038a6a617f6501921bcc8be9d2046386/raw", :target => "_blank" } Current Data
      %a{ :href => "#", :onclick => "startStreetDriver(); return false" } Start SD
      %a{ :href => "#", :onclick => "stopStreetDriver(); return false" } stop SD

    #url
    #map
    #pano
    #pano2

    :javascript
      var panorama, map, panoramaOptions, panorama2, lastobjid = null;
      var streetDriverTimeout = null;
      var sdVisited = [], sdNotVisited = {};

      function createSun() {
        var link = $($('#pano').find('.gm-iv-address-link')[0]).find("a")
                                                              .attr("href");
        $.get("/add?l=" + encodeURIComponent(link),
              function(data){
                $('#createsun').html("Done")
              })
              .fail( function(){$('#createsun').html("Error")})

      }

      function nextLocation() {
        $.get( "/image?l="+lastobjid, function(data) {
                 map.setCenter( data.location )
                 panorama2.setPano(data.id)
                 panorama.setPov(data.pov)
                 panorama.setZoom(data.zoom)
                 lastobjid = data.objid;
                 $('#details').attr('href', "https://store.staging.pushtech.de/store/details/" + data.objid);
               })
      }

      function linkClosestsToHeading() {
        var links = panorama.getLinks();
        if ( links.length === 1 ) { return links[0]; }

        var currentHeading = panorama.getPov().heading;
        var lnks = links.sort(function(a,b){
          var hA = a.heading, hB = b.heading;
          hA = hA < 0 ? hA + 360 : hA;
          hB = hB < 0 ? hB + 360 : hB;
          return Math.abs(currentHeading-hA) > Math.abs(currentHeading-hB);
        });

        return cacheLinks(lnks);
      }

      function cacheLinks(links) {
        var returnLink = null;

        _.each( links, function(elem,idx) {
          if ( _.indexOf( sdVisited, elem.pano ) < 0 ) {
            sdNotVisited[elem.pano] = elem;
          }
        });

        if ( _.indexOf( sdVisited, links[0].pano) < 0 ) {
          returnLink = links[0];
        } else {
          var link = sdNotVisited[_.last(_.keys(sdNotVisited))];
          if ( link === undefined ) { return false; }
          setHeading( link );
          returnLink = link;
        }

        //if ( sdVisited.length > 150 ) {
        //  sdVisited = sdVisited.slice(1, 151);
        //}
        sdVisited.push(returnLink.pano);
        delete sdNotVisited[returnLink.pano]
        return returnLink;
      }

      function followLink() {
        var link = linkClosestsToHeading();
        if (! link ) {
          alert("We've lost contact")
          clearTimeout( streetDriverTimeout );
          return false;
        }
        setHeading(link);
        panorama.setPano(link.pano);
        return true;
      }

      function startStreetDriver() {
        sdVisited = [];
        sdNotVisited = {};
        streetDriver();
      }

      function stopStreetDriver() {
        if ( streetDriverTimeout !== null ) {
          clearTimeout( streetDriverTimeout );
          streetDriverTimeout = null;
        }
      }

      function streetDriver() {
        if ( followLink() ) {
          streetDriverTimeout = setTimeout(function() {
             streetDriver()
          }, 3500);
        }
      }

      function setHeading(link) {
        var heading = link.heading;
        if ( heading < 0 ) { heading += 360 }
        var pov = panorama.getPov();
        pov.heading = heading;
        panorama.setPov(pov);
      }

      function initialize() {
        google.maps.streetViewViewer = 'photosphere';
        var start = {lat: 36.058946, lng: -86.789344};

        panoramaOptions = {
            position: start,
            mode: 'webgl',
            clickToGo: true,
            addressControlOptions: {
                position: google.maps.ControlPosition.BOTTOM_LEFT
            },
            linksControl: true,
            panControl:false,
            enableCloseButton: false,
            zoomControlOptions:{
                position:google.maps.ControlPosition.RIGHT_TOP
            },
            showRoadLabels: false,
            pov: {
              heading: 0,
              pitch: 10
            }
        };

        map = new google.maps.Map(document.getElementById('map'), {
          center: start,
          zoom: 14
        });
        panorama = new google.maps.StreetViewPanorama(
                          document.getElementById('pano'), panoramaOptions);
        map.setStreetView(panorama);

        panorama2 = new google.maps.StreetViewPanorama(
                          document.getElementById('pano2'), panoramaOptions);

        google.maps.event.addListener(panorama, "pov_changed", function() {
          document.getElementById('url').innerHTML = $($('#pano')
                      .find('.gm-iv-address-link')[0]).find("a").attr("href");
          $('#createsun').html("Create Sun")
        });
        google.maps.event.addListener(panorama, "pano_changed", function() {
          document.getElementById('url').innerHTML = $($('#pano')
                      .find('.gm-iv-address-link')[0]).find("a").attr("href");
          $('#createsun').html("Create Sun")
        })
        google.maps.event.addListener(panorama2, "pano_changed", function() {
           if ( !(panorama2.getPano().match(/F:/)) ) {
             panorama.setPano( panorama2.getPano() );
           }
        });
        nextLocation()
      }
    %script{:async => "", :defer => "defer", :src => "https://maps.googleapis.com/maps/api/js?key=#{ENV['GOOGLE_API_KEY']}&callback=initialize"}
      :cdata
