# coding: utf-8
['sinatra','haml','thin','rest-client','yaml'].map { |a| require(a) }

namespace :webapp do
  desc "Run a simple webserver on top of kubectl"
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

  def y_to_zoom(y,lat)
    Math.log(156543.03392 * Math.cos(lat * Math::PI / 180) / y, 2)
  end

  get '/export' do
    content_type :text
    u,p = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
    data = JSON(RestClient.get("https://#{u}:#{p}@store.staging.pushtech.de"+
                               "/offers?owner=GoogleAlbum"))["data"].
             select { |a| a["text"] =~ /looking straight at the sun/i }

    { :date => DateTime.now.to_s,
      :data => data.map { |a| [a["_id"],a["extdata"]["link"]] }
    }.to_yaml
  end

  get '/duplicate' do
    u,p = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
    data = JSON(RestClient.get("https://#{u}:#{p}@store.staging.pushtech.de"+
                               "/offers?owner=GoogleAlbum"))["data"].
             select { |a| a["text"] =~ /looking straight at the sun/i }

    @dups = data.map { |a| [a["_id"],a["extdata"]["link"]] }.
              group_by do |(_,link)|
                link =~ /@([-?[:digit:]\.]+),([-?[:digit:]\.]+).+,([-?[:digit:]\.]+)y.*,([-?[:digit:]\.]+)h.*,([-?[:digit:]\.]+)t.+\!1s(.+)\!2e/
                $6
              end.to_a.select { |(_,b)| b.size > 1 }

    haml :duplicates, :layout => false
  end

  get '/image' do
    content_type :json
    body = RestClient.get("https://gist.githubusercontent.com"+
                          "/gorenje/038a6a617f6501921bcc8be9d2046386/raw").body
    objid,link = YAML.load(body)[:data].reject {|a| a.first == params[:l]}.sample

    puts link
    link =~ /@([-?[:digit:]\.]+),([-?[:digit:]\.]+).+,([-?[:digit:]\.]+)y.*,([-?[:digit:]\.]+)h.*,([-?[:digit:]\.]+)t.+\!1s(.+)\!2e/

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
      :zoom => y_to_zoom($3.to_f, $1.to_f).to_i
    }.to_json
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
        height: 90%;
        width: 45%;
      }
  %body
    %h1
      Looking at the Sun
      %button{ :onclick => "nextLocation();" } Next Sun
      %button#createsun{ :onclick => "createSun();" } Create Sun
      %a#details{ :href => "", :target => "_blank" } Details
    #url
    #map
    #pano
    #pano2
    %br{:clear => "all"}/

    :javascript
      var panorama, map, panoramaOptions, panorama2, lastobjid = null;
      function createSun() {
        var link = $($('#pano').find('.gm-iv-address-link')[0]).find("a")
                                                              .attr("href");
        $.get("http://localhost:3001/add?l=" + encodeURIComponent(link),
              function(data){
                $('#createsun').html("Done")
              })
              .fail( function(){$('#createsun').html("Error")})

      }

      function nextLocation() {
        $.get( "http://localhost:3001/image?l="+lastobjid, function(data) {
                 map.setCenter( data.location )
                 panorama2.setPano(data.id)
                 // setTimeout(function(){
                   panorama.setPov(data.pov)
                   panorama.setZoom(data.zoom)
                 //},1000)
                 lastobjid = data.objid;
                 $('#details').attr('href', "https://store.staging.pushtech.de/store/details/" + data.objid);
               })
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
