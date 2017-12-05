function setup_for_create_search() {
  current_location = new google.maps.LatLng(user_location.coords.latitude,
                                            user_location.coords.longitude);

  circle = new google.maps.Circle({
    map: map,
    radius: InitialCircleRadiusMeters,
    center: current_location,
    strokeColor: '#000',
    strokeOpacity: 0.8,
    strokeWeight: 2,
    fillColor: '#000',
    fillOpacity: 0.25,
    editable: true
  });

  circle._ignoreNextCall = false
  circle.addListener('bounds_changed', showNewCircle);

  youmarker.setDraggable(true);
  youmarker.setIcon(newIcon("/images/marker/+.svg?c=%23888"))
  youmarker.setPosition(current_location);
  youmarker.addListener('dragend', positionChanged);

  map.fitBounds(circle.getBounds());
  map.setCenter(current_location);

  showNewCircle();
  $('#latfld').val(current_location.lat());
  $('#lngfld').val(current_location.lng());

  var latlng = {lat: current_location.lat(), lng: current_location.lng() };
  (new google.maps.Geocoder).geocode({'location': latlng},
    function(results, status) {
      if ( results ) {
        $('.address').val(results[0].formatted_address);
      }
    });
}

function obtainOfferObject() {
  $.ajax({
    url:  "/api/offers.json",
    data: { id: offer_obj["_id"] },
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    var bounds =
        new google.maps.LatLngBounds(current_location,current_location);

    $.each(objectmarkers, function(idx, obj) {
      obj.setMap(null);
    });

    $.each(data, function(idx, offer_obj) {
      bounds.extend(offer_obj.json_location);
      var lat = offer_obj.json_location.lat,
          lng = offer_obj.json_location.lng,
          latDelta = offer_obj.latDelta,
          lngDelta = offer_obj.lngDelta;

      var coords = [
        {lat: lat + latDelta, lng: lng - lngDelta},
        {lat: lat + latDelta, lng: lng + lngDelta},
        {lat: lat - latDelta, lng: lng + lngDelta},
        {lat: lat - latDelta, lng: lng - lngDelta},
      ];

      bounds.extend(coords[0]);
      bounds.extend(coords[1]);
      bounds.extend(coords[2]);
      bounds.extend(coords[3]);

      if ( typeof objectmarkers[idx] === 'undefined' ) {
        objectmarkers[idx] = newObjectMarker({});
      }
      objectmarkers[idx].setPosition(offer_obj.json_location);
      objectmarkers[idx].setTitle(offer_obj.text);
      objectmarkers[idx].setMap(map);
      objectmarkers[idx].setIcon(newIcon(offer_obj.marker_icon));
    });

    map.fitBounds(bounds);
  });
}

$(document).ready(function(){
  $(document).on('mapinitialized.veryfirsttime', function() {
    $(document).off('.veryfirsttime');
    setup_for_create_search();
    if ( offer_obj["_id"] ) {
      obtainOfferObject();
    }
  });

  $('#addressselector').on('change', function(){
    if (!$('#addressselector').find('option:selected')) return;

    var dataObj = $('#addressselector').find('option:selected').data().obj;
    if (dataObj) {
      usePinUpdateMap(dataObj);
    }
  });
});
