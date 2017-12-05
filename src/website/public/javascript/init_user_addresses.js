function positionChangedUserAddress() {
  var p = youmarker.getPosition();
  current_location = new google.maps.LatLng(p.lat(), p.lng());

  $('#latfld').val(p.lat());
  $('#lngfld').val(p.lng());

  var latlng = {lat: p.lat(), lng: p.lng() };
  (new google.maps.Geocoder).geocode({'location': latlng},
    function(results, status) {
      $('#address').html(results[0].formatted_address);
    });

  if ( typeof youmarker._circle === "undefined" ) {
    youmarker._circle = newCircle();
    youmarker._circle.setEditable(true);
    youmarker._circle.setRadius(InitialCircleRadiusMeters);
    youmarker._circle.addListener('bounds_changed', function(){
      $('#radius').html(Math.ceil(youmarker._circle.getRadius()));
    });
  }

  youmarker._circle.setMap(map);
  youmarker._circle.setCenter(p);
}

function setup_for_user_address() {
  youmarker.setDraggable(true);
  youmarker.addListener('dragend', positionChangedUserAddress);
  youmarker.setIcon(newIcon("/images/marker/+.svg?c=%23888"));
}

function updateAddressList() {
  $.ajax({
    url:  "/api/addresses",
    data: {},
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#resultslist').html('');
    hideAllObjectmarkers();

    $.each(data, function(idx, address_obj) {
      $('#resultslist').append(address_obj.resultslist_html);
      if ( typeof objectmarkers[idx] === 'undefined' ) {
        objectmarkers[idx] = newObjectMarker({});
      }

      objectmarkers[idx].setPosition(address_obj.json_location);
      objectmarkers[idx].setTitle(address_obj.name);
      objectmarkers[idx].setMap(map);
      objectmarkers[idx]._icon      = newIcon(address_obj.marker_icon)
      objectmarkers[idx]._icon_hi   = newIcon(address_obj.marker_icon_highlight)
      objectmarkers[idx]._ranking   = address_obj.ranking_num;
      objectmarkers[idx]._objid     = address_obj.id;
      objectmarkers[idx].setIcon(objectmarkers[idx]._icon);
      objectmarkers[idx].setDraggable(true);

      if (typeof objectmarkers[idx]._circle === 'undefined') {
        objectmarkers[idx]._circle = newCircle();
        objectmarkers[idx]._circle.setEditable(true);
      }
      google.maps.event.
         clearListeners(objectmarkers[idx]._circle, 'bounds_changed');
      objectmarkers[idx]._circle.setCenter(address_obj.json_location);
      objectmarkers[idx]._circle.setRadius(address_obj.radius);

      objectmarkers[idx]._circle.addListener('bounds_changed', function(){
        var SELF = objectmarkers[idx];
        $('#resultslistitem' + SELF._ranking + ' .radius')
                     .html(Math.ceil(SELF._circle.getRadius()));
      });

      google.maps.event.clearListeners(objectmarkers[idx], 'dragend');
      objectmarkers[idx].addListener('dragend', function(){
        var SELF = objectmarkers[idx];
        var p = SELF.getPosition();
        var latlng = {lat: p.lat(), lng: p.lng() };
        (new google.maps.Geocoder).geocode({'location': latlng},
          function(results, status) {
            $('#resultslistitem'+SELF._ranking+' .street_name')
                  .html(results[0].formatted_address);
          });
        SELF._circle.setCenter(latlng);
        highlightMarker(SELF._ranking);
      });
    })
    $(document).trigger("addresslistupdatecomplete");
  });
}

function deleteAddress(idstr) {
  startWaiting();
  $.ajax({
    url:  "/api/address/" + idstr + "/delete",
    data: {},
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    updateAddressList();
    stopWaiting();
  });
}

function updateAddress(idstr, ranking_num) {
  var objectmarker = null;
  $.each(objectmarkers, function(idx, obj) {
    if ( obj._ranking == ranking_num ) {
      objectmarker = obj;
      return;
    }
  });

  if ( !objectmarker ) return false;

  var bnds = objectmarker._circle.getBounds();
  var sw = bnds.getSouthWest();
  var ne = bnds.getNorthEast();
  var p = objectmarker._circle.getCenter();

  startWaiting();
  $.ajax({
    url:  "/api/address/" + idstr + "/update",
    data: { sw: {latitude: sw.lat(), longitude: sw.lng() },
            ne: {latitude: ne.lat(), longitude: ne.lng() },
            lat: p.lat(),
            lng: p.lng(),
            radius: Math.ceil(objectmarker._circle.getRadius()),
            address: $('#resultslistitem'+ ranking_num +" .street_name").html(),
          },
    method: 'post',
    dataType: 'json'
  }).done(function(data){
    stopWaiting();
  })

  return false;
}

function addAddress(name) {
  var bnds = map.getBounds();
  var sw = bnds.getSouthWest();
  var ne = bnds.getNorthEast();
  var p = youmarker.getPosition();

  startWaiting();

  $.ajax({
    url:  "/api/address/create",
    data: { name: name,
            sw: {latitude: sw.lat(), longitude: sw.lng() },
            ne: {latitude: ne.lat(), longitude: ne.lng() },
            lat: p.lat(),
            lng: p.lng(),
            radius: $('#radius').html(),
            address: $('#address').html(),
          },
    method: 'post',
    dataType: 'json'
  }).done(function(data){
    updateAddressList();
    $('#address_name').val("");
    stopWaiting();
  });
}

$(document).ready(function(){
  $(document).on('mapinitialized.veryfirsttime', function() {
    $(document).off('.veryfirsttime');
    setup_for_user_address();
    updateAddressList();
  });

  $(document).on('addresslistupdatecomplete.onlyforthefirsttime', function() {
    $(document).off('.onlyforthefirsttime');
    var bnds = new google.maps.LatLngBounds(current_location,current_location);
    $.each(objectmarkers, function(idx, obj){
      bnds.extend(obj.getPosition());
    });
    map.fitBounds(bnds);
  });

  $('#address_name').on('keypress', function(ev){
    var keycode = (ev.keyCode ? ev.keyCode : ev.which);
    if (keycode == '13') {
      addAddress($('#address_name').val());
    }
  });

  $(document).on('updatedlocation.firstcall', function(){
    $(document).off('.firstcall');
    var latlng = {lat: current_location.lat(), lng: current_location.lng() };
    (new google.maps.Geocoder).geocode({'location': latlng},
      function(results, status) {
        $('#address').html(results[0].formatted_address);
      });

    if (youmarker) { youmarker.setPosition(current_location); }
    updateUserLocation(current_location);
  });
});
