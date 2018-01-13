var paginationGroupSize = 20;
var paginationCurrentGroup = null;

function getURLParameter(name) {
  return decodeURIComponent((new RegExp('[?|&]' + name + '=' +
    '([^&;]+?)(&|#|;|$)').
    exec(location.search) || [null, ''])[1].replace(/\+/g, '%20')) ||
  null;
}

function updateLocation() {
  updateMarkers(clToPosition());
}

function startWaiting() {
  $('#waitingForGedot').fadeIn(500);
}

function stopWaiting() {
  $('#waitingForGedot').fadeOut(500);
}

function newObjectMarker(opts) {
  opts['zIndex'] = google.maps.Marker.MAX_ZINDEX - 1;
  return setUpMarkerClickListener(new google.maps.Marker(opts));
}

function newIcon(url) {
  return {
    size: new google.maps.Size(30, 38),
    origin: new google.maps.Point(0, 0),
    anchor: new google.maps.Point(15, 38),
    url: url
  };
}

function constructPagination(data) {
  $('#pagination').html("")

  if ( data.length > paginationGroupSize ) {
    var groups = Math.ceil(data.length / paginationGroupSize)
    for ( var idx = 0; idx < groups; idx++ ) {
      $('#pagination').append("<a id='pgnpage" + idx +
                               "' class='pgnpagelink' href='#' "+
                               "onclick='displayGroup(" + idx +
                              ");'>" + (idx+1) + "</a>");
      returnedOffers[idx] = data.slice(idx*paginationGroupSize,
                                       (idx+1)*paginationGroupSize);
    }
    $('#pgnpage0').click();
  } else {
    displayData(data);
  }
}

function positionChanged() {
  var p = youmarker.getPosition();
  current_location = new google.maps.LatLng(p.lat(), p.lng());
  showNewCircle();
  $('#latfld').val(p.lat());
  $('#lngfld').val(p.lng());

  var latlng = {lat: p.lat(), lng: p.lng() };
  (new google.maps.Geocoder).geocode({'location': latlng},
    function(results, status) {
      if ( results ) {
        $('.address').val(results[0].formatted_address);
      }
    });
}

function displayGroup(idx) {
  paginationCurrentGroup = idx;
  displayData(returnedOffers[idx]);
  $('.pgnpagelink').removeClass('highlight');
  $('#pgnpage' + idx).addClass('highlight');
}

function newCircle() {
  return new google.maps.Circle({
    strokeColor: '#000',
    strokeOpacity: 0.3,
    strokeWeight: 2,
    fillColor: '#000',
    fillOpacity: 0.1,
    zIndex: google.maps.Marker.MIN_ZINDEX
  });
}

function usePinUpdateMap(data) {
  current_location = new google.maps.LatLng(data.latitude,
                                            data.longitude);
  youmarker.setPosition(current_location);

  var circleBounds = new google.maps.Circle({
    center: current_location,
    radius: parseInt(data.bounds.radius),
  });

  map.setCenter(current_location);
  map.fitBounds(circleBounds.getBounds());
  circle.setCenter(current_location);

  $('#latfld').val(current_location.lat());
  $('#lngfld').val(current_location.lng());
  $('.address').val(data.street_1);
}

function usePinUpdateBounds(data) {
  current_location = new google.maps.LatLng(data.latitude,
                                            data.longitude);
  var circleBounds = new google.maps.Circle({
    center: current_location,
    radius: parseInt(data.bounds.radius),
  });

  map.setCenter(current_location);
  map.fitBounds(circleBounds.getBounds());

  $(document).trigger("mapchanged");
}

function hideAllObjectmarkers() {
  $.each(objectmarkers, function(idx, obj) {
    obj.setMap(null);
    if (obj._circle) obj._circle.setMap(null);
  });
}

function initializeObjectMarkerForSubject(subject, idx) {
  $('#resultslist').append(subject.resultslist_html);

  if ( typeof objectmarkers[idx] === 'undefined' ) {
    objectmarkers[idx] = newObjectMarker({});
  }
  objectmarkers[idx].setPosition(subject.json_location);
  objectmarkers[idx].setTitle(subject.text);

  objectmarkers[idx]._icon    = newIcon(subject.marker_icon)
  objectmarkers[idx]._icon_hi = newIcon(subject.marker_icon_highlight)

  if (typeof objectmarkers[idx]._circle === 'undefined') {
    objectmarkers[idx]._circle = newCircle();
  }
  objectmarkers[idx]._circle.setCenter(subject.json_location);
  objectmarkers[idx]._circle.setRadius(subject.radius);

  objectmarkers[idx]._objid = subject._id;
  objectmarkers[idx]._ranking = subject.ranking_num
  objectmarkers[idx].setMap(map);
  objectmarkers[idx].setIcon(objectmarkers[idx]._icon);
}

function initMap() {
  if (typeof(listenForLocationChange) !== "undefined") {
    listenForLocationChange();
  }

  var defaultPosition = {
    coords: {
      latitude: 52.458823227696975,
      longitude: 13.33830926567316
    }
  }

  setUpMap(current_location || defaultPosition);
}

function showNewCircle() {
  if ( circle._ignoreNextCall ) {
    circle._ignoreNextCall = false;
    return;
  }

  var lat = current_location.lat();
  var lng = current_location.lng();

  var ne = circle.getBounds().getNorthEast();
  var sw = circle.getBounds().getSouthWest();

  $('#crlRadius').val(Math.ceil(circle.getRadius()));
  $('#radiusText').html(Math.ceil(circle.getRadius()));

  circle._ignoreNextCall = true;
  circle.setCenter(current_location);
}

function ajaxStartChatCall(params) {
  startWaiting();
  $.ajax({
    url: '/api/startchat',
    data: params,
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    if (data.status == "error" ) {
      alert(data.msg);
    } else {
      if ( sbWidget.sb.isConnected() ) {
        sbWidget.showChannel(data.channelUrl);
      } else {
        sbWidget.startWithConnect(sendbird_app_id, data.userid,
          data.nickname, function() {
            sbWidget.showChannel(data.channelUrl);
          });
      }
    }
    stopWaiting();
  });
}

function startChatUsingChannelUrl(channel_url) {
  ajaxStartChatCall({channel_url: channel_url})
  return false;
}

function startChatWithOwner(objid, ranking_num) {
  if (ranking_num) {
    highlightMarker(ranking_num);
  }
  ajaxStartChatCall({objid: objid});
  return false;
}

function highlightMarker(ranking){
  var return_obj = null;
  $('#resultslist li').removeClass('highlight');
  $.each(objectmarkers, function(idx, obj) {
    if ( obj._ranking == ranking ) {
      google.maps.event.trigger(obj,'click');
      return_obj = obj;
      return;
    }
  });
  return return_obj;
}

function setUpMarkerClickListener(marker) {
  marker.addListener('click', function(){
    $('#resultslist li').removeClass('highlight');
    directionsDisplay.setDirections({routes: []});

    $.each(objectmarkers, function(idx, obj){
      obj.setZIndex(google.maps.Marker.MAX_ZINDEX - 1);
      obj.setIcon(obj._icon);
      if (obj._circle) obj._circle.setMap(null);
    });

    marker.setZIndex(google.maps.Marker.MAX_ZINDEX);
    marker.setIcon(marker._icon_hi);

    var request = {
      origin: youmarker.getPosition(),
      destination: marker.getPosition(),
      travelMode: google.maps.TravelMode.WALKING,
      unitSystem: google.maps.UnitSystem.METRIC,
    };

    if (marker._circle) marker._circle.setMap(map);
    $('#resultslistitem' + marker._ranking).addClass("highlight");

    var paginationOffset = 0;
    var heightListElement =
       $('#resultslist').innerHeight() / $('#resultslist li').length;

    if ( paginationCurrentGroup ) {
      paginationOffset =
        paginationCurrentGroup * paginationGroupSize * heightListElement;
    }
    var offset = (heightListElement * (marker._ranking-1)) - paginationOffset;


    $('#rlcnter').animate({scrollTop: offset}, 1000);

    var directionsService = new google.maps.DirectionsService();
    directionsService.route(request, function(result, status) {
      if (status == 'OK') {
        var rt = result.routes[directionsDisplay.getRouteIndex()];
        // directionsDisplay.setDirections(result);

        var totaltime = 0, totaldistance = 0;
        $.each(rt.legs, function(idx, leg){
          totaldistance += leg.distance.value;
          totaltime += leg.duration.value;
        });

        $('#wktime' + marker._ranking).html(Math.ceil(totaltime/60))
        $('#addrline' + marker._ranking).
          html(rt.legs[rt.legs.length-1].end_address);
        $('#wkdist' + marker._ranking).html((totaldistance/1000).toFixed(1));
      }
    });
  });
  return marker;
}

function mapStyle(){
  return [
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "stylers": [
        {
          "visibility": "on"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ];
}

function centerControl(map) {
  var centerControlDiv = document.createElement('div');

  // Set CSS for the control border.
  var controlUI = document.createElement('div');
  controlUI.style.backgroundColor = '#fff';
  controlUI.style.border = '2px solid #fff';
  controlUI.style.borderRadius = '3px';
  controlUI.style.boxShadow = '0 2px 6px rgba(0,0,0,.3)';
  controlUI.style.cursor = 'pointer';
  controlUI.title = 'Click to update results';
  centerControlDiv.appendChild(controlUI);

  // Set CSS for the control interior.
  var controlText = document.createElement('div');
  controlText.style.height = '30px';
  controlText.style.width = '30px';
  controlText.innerHTML =
    "<img width=30 height=30 src='/images/reloader.svg'/>";
  controlUI.appendChild(controlText);

  // Setup the click event listeners: simply set the map to Chicago.
  controlUI.addEventListener('click', function() {
    $(document).trigger("mapchanged");
    $('#updateresultsdiv').addClass('hidden');
  });

  centerControlDiv.index = 1;
  centerControlDiv.id = 'updateresultsdiv';
  centerControlDiv.style['padding-top'] = '10px';
  centerControlDiv.style['padding-right'] = '10px';
  centerControlDiv.classList.add('hidden');

  return centerControlDiv;
}

function setUpMap(position) {
  var lat = position.coords.latitude,
      lng = position.coords.longitude;

  var origin = new google.maps.LatLng(lat,lng);

  $(document).trigger('setmapheight');

  map = new google.maps.Map(document.getElementById('map'), {
    zoom: 14,
    center: origin,
    gestureHandling: 'greedy',
    mapTypeControl: false,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    styles: mapStyle(),
    disableDefaultUI: true,
    streetViewControl: false,
    zoomControl: true,
    zoomControlOptions: {
      position: google.maps.ControlPosition.TOP_LEFT
    }
  });

  map.controls[google.maps.ControlPosition.RIGHT_TOP].push(centerControl(map));

  map.addListener('tilesloaded', function() {
    $(document).trigger("mapinitialized");
  });
  map.addListener('zoom_changed', function() {
    $(document).trigger("mapboundschanged");
  });
  map.addListener('dragend', function() {
    $(document).trigger("mapboundschanged");
  });
  $(document).on("mapboundschanged", function(){
    $('#updateresultsdiv').removeClass('hidden');
  });

  setUpMarkers(origin);
}

function setUpMarkers(origin) {
  youmarker = new google.maps.Marker({
    position: origin,
    map: map,
    title: "You",
    zIndex: google.maps.Marker.MAX_ZINDEX - 1
  });

  youmarker.setIcon(newIcon('/images/marker/blank.svg'));

  directionsDisplay = new google.maps.DirectionsRenderer({
    suppressInfoWindows: true,
    suppressMarkers: true,
    preserveViewport: true,
    routeIndex: 0,
    map: map,
    polylineOptions: {
      strokeColor: "#333"
    }
  });
}

function updateUserLocation(loc) {
  if ( last_good_known_lat != loc.lat() || last_good_known_lng != loc.lng() ) {
    last_good_known_lat = loc.lat();
    last_good_known_lng = loc.lng();

    $.ajax({
      url: '/user/location',
      data: { lat: loc.lat(), lng: loc.lng() },
      method: 'get',
      dataType: 'json'
    });
  }
}
