function getSearchesForOffer(text) {
  $('#resultslist').addClass('hidden');
  startWaiting();
  $.ajax({
    url: '/whatareyouoffering',
    data: { text: text },
    method: 'post',
    dataType: 'json'
  }).done(function(data){
    $('#resultslist').removeClass('hidden');
    $('#resultslisttitle').removeClass('hidden');
    $.each(data, function(idx, search_obj) {
      $('#resultslist').append(search_obj.resultslist_html);
    });
    stopWaiting();
  });
}

function updateResultslist() {
  $('#resultslist').html('');
  getSearchesForOffer($('#inputfield').val());
}

function createOfferForSearch(srchid) {
  startWaiting();
  $.ajax({
    url:  "/api/user/offer/" + srchid + "/create",
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
    stopWaiting();
    dialog.dialog("open");
  });
  return false;
}

function submitCreateOfferForm() {
  startWaiting();
  $.ajax({
    url: $('#createofferform').attr("action"),
    method: $('#createofferform').attr("method"),
    data: $('#createofferform').serialize(),
    dataType: 'json'
  }).done(function(data){
    stopWaiting();
    dialog.dialog('close');
  });
}

$(document).ready(function(){
  listenForLocationChange();
  $(document).on('updatedlocation', function(){
    updateUserLocation(current_location);
  });

  $('#inputfield').on('keypress', function(ev){
    var keycode = (ev.keyCode ? ev.keyCode : ev.which);
    if (keycode == '13') {
      updateResultslist()
    }
  });
});
