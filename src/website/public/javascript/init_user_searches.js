function activateSubject(objid, ranking_num){
  startWaiting();
  $.ajax({
    url: "/api/user/search/" + objid + "/set_active/true",
    data: { fromlisting: ranking_num },
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#resultslistitem'+ranking_num).removeClass("deactivated");
    $('#actbut'+ranking_num).replaceWith(data.html);
    stopWaiting();
  });
}

function deactivateSubject(objid, ranking_num){
  startWaiting();
  $.ajax({
    url: "/api/user/search/" + objid + "/set_active/false",
    data: { fromlisting: ranking_num },
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#resultslistitem'+ranking_num).addClass("deactivated");
    $('#actbut'+ranking_num).replaceWith(data.html);
    stopWaiting();
  });
}

function deleteSubject(objid) {
  startWaiting();
  $.ajax({
    url: "/api/user/search/" + objid + "/delete",
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $.each(objectmarkers, function(idx,obj){
      if (obj._objid === objid) {
        obj.setMap(null);
        obj._circle.setMap(null);
        $('#resultslistitem' + obj._ranking).hide();
      }
    });
    stopWaiting();
  });
}

function editSubject(objid) {
  window.location = window.location.protocol + "//" +
    window.location.hostname + ":" +
    window.location.port + "/search/" + objid + "/edit";
}

function checkForMatchingSubject(objid) {
  $.ajax({
    url: "/api/user/search/" + objid + "/match",
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    alert( data.status );
  });
}

function mapChangedCallback() {
  var bnds = map.getBounds();
  var sw = bnds.getSouthWest();
  var ne = bnds.getNorthEast();

  startWaiting();
  $.ajax({
    url:  "/api/user/searches.json",
    data: { keywords: $('#searchterms').val(),
            sw: {latitude: sw.lat(), longitude: sw.lng() },
            ne: {latitude: ne.lat(), longitude: ne.lng() }
          },
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    directionsDisplay.setDirections({routes: []});

    $('#resultslist').html('');
    hideAllObjectmarkers();

    $.each(data, function(idx, search_obj) {
      initializeObjectMarkerForSubject(search_obj, idx)
    });
    stopWaiting();
  });
}

$(document).ready(function(){
  $(document).on('mapinitialized.firstcallinitmap', function() {
    $(document).off('.firstcallinitmap');
    youmarker.setMap(null);
    if (current_location) map.setCenter(current_location);
    mapChangedCallback();
  });

  $(document).on('mapchanged', mapChangedCallback);

  $(document).on('updatedlocation', function(){
    updateUserLocation(current_location);
  });

  $('#addressselector').on('change', function(){
    if (!$('#addressselector').find('option:selected')) return;

    var dataObj = $('#addressselector').find('option:selected').data().obj;
    if (dataObj) {
      usePinUpdateBounds(dataObj);
    }
  });

  $('#searchterms').on('keypress', function(ev){
    var keycode = (ev.keyCode ? ev.keyCode : ev.which);
    if (keycode == '13') {
      mapChangedCallback();
    }
  });
});
