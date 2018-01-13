function deleteSubject(objid){
  startWaiting();
  $.ajax({
    url: "/api/user/offer/" + objid + "/delete",
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    window.location = window.location.protocol + "//" +
                      window.location.hostname + ":" +
                      window.location.port + "/user/offers";
    stopWaiting();
  });
}

function deactivateSubject(objid){
  startWaiting();
  $.ajax({
    url: "/api/user/offer/" + objid + "/set_active/false",
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#actbuthome').html(data.html);
    stopWaiting();
  });
}

function activateSubject(objid){
  startWaiting();
  $.ajax({
    url: "/api/user/offer/" + objid + "/set_active/true",
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#actbuthome').html(data.html);
    stopWaiting();
  });
}

function setup_for_update_offer() {
  current_location = new google.maps.LatLng(offer_obj.location.coordinates[1],
                                            offer_obj.location.coordinates[0]);

  circle = new google.maps.Circle({
    map: map,
    radius: offer_obj.radiusMeters || InitialCircleRadiusMeters,
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

$(document).ready(function(){
  $(document).on('mapinitialized.veryfirsttime', function() {
    $(document).off('.veryfirsttime');
    setup_for_update_offer();
  });

  $('#addressselector').on('change', function(){
    if (!$('#addressselector').find('option:selected')) return;

    var dataObj = $('#addressselector').find('option:selected').data().obj;
    if (dataObj) {
      usePinUpdateMap(dataObj);
      circle.setRadius(parseInt(dataObj.bounds.radius));
    }
  });
});
