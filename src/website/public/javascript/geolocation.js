var watch_position_id = null;
var current_location = null;

function listenForLocationChange() {
  watch_position_id =
    navigator.geolocation.watchPosition(updateCurrentLocation);
}

function stopListeningForLocationChange() {
  if ( watch_position_id !== null ) {
    navigator.geolocation.clearWatch(watch_position_id);
    watch_position_id = null;
  }
}

function updateCurrentLocation(pos) {
  if ( typeof(google) === "undefined" ) {
    current_location = {
      _lat: pos.coords.latitude,
      _lng: pos.coords.longitude,
      lat: function() { return this._lat; },
      lng: function() { return this._lng; }
    }
  } else {
    current_location = new google.maps.LatLng(pos.coords.latitude,
                                              pos.coords.longitude);
  }
  $(document).trigger('updatedlocation');
}

function clToPosition() {
  return {
    coords: {
      latitude: current_location.lat(),
      longitude: current_location.lng()
    }
  };
}
