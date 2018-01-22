var returnedOffers = {};

function createSubjectFromSubject(offerid, ranking) {
  highlightMarker(ranking);
  startWaiting();
  $.ajax({
    url:  "/api/user/search/" + offerid + "/create",
    data: {},
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#dialog-form').html(data.form);
    dialog = $("#dialog-form").dialog({
      title:    data.title,
      autoOpen: false,
      height:   200,
      width:    320,
      modal:    true,
      close:    function() {}
    });
    stopWaiting()
    dialog.dialog("open");
  }).fail(function(){
    stopWaiting();
  });
}

function submitCreateSearchForm() {
  $.ajax({
    url:    $('#createsearchform').attr("action"),
    method: $('#createsearchform').attr("method"),
    data:   $('#createsearchform').serialize(),
    dataType: 'json'
  }).done(function(data){
    dialog.dialog('close');
  });
}

function displayData(data){
  directionsDisplay.setDirections({routes: []});
  $('#resultslist').html('');
  hideAllObjectmarkers();

  $.each(data, function(idx, search_obj) {
    initializeObjectMarkerForSubject(search_obj, idx);
  });
}

function mapChangedCallback() {
  var bnds = map.getBounds();
  var sw = bnds.getSouthWest();
  var ne = bnds.getNorthEast();

  $('#pagination').html("")
  returnedOffers = {}
  startWaiting();

  $.ajax({
    url:  "/api/offers.json",
    data: { keywords: $('#searchterms').val(),
            sw: {latitude: sw.lat(), longitude: sw.lng() },
            ne: {latitude: ne.lat(), longitude: ne.lng() }
    },
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    constructPagination(data);
    stopWaiting();
  }).fail(function(){
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

  $(document).on('updatedlocation', function(){
    updateUserLocation(current_location);
  });

  $('#searchterms').on('keypress', function(ev){
    var keycode = (ev.keyCode ? ev.keyCode : ev.which);
    if (keycode == '13') {
      mapChangedCallback();
    }
  });

  $(document).on('mapchanged', mapChangedCallback);

  $('#addressselector').on('change', function(){
    if (!$('#addressselector').find('option:selected')) return;

    var dataObj = $('#addressselector').find('option:selected').data().obj;
    if (dataObj) {
      usePinUpdateBounds(dataObj);
    }
  });
});
