function getSearchesForOffer(text) {
  $('#resultslist').addClass('hidden');
  startWaiting();
  $.ajax({
    url: '/whatareyouoffering',
    data: { text: text },
    method: 'post',
    dataType: 'json'
  }).done(function(data){
    $('#resultslisttitle').removeClass('hidden');
    $('#resultslist').removeClass('hidden');
    $.each(data, function(idx, search_obj) {
      $('#resultslist').append(search_obj.resultslist_html);
    });
    stopWaiting();
  }).fail(function(){
    stopWaiting();
  });
}

function showDialogWindow(params) {
  $.ajax({
    url: '/whatareyouoffering/dialog',
    data: params,
    method: 'get',
    dataType: 'json'
  }).done(function(data){
    $('#dialog-form').html(data.form);
    dialog = $("#dialog-form").dialog({
      title:    data.title,
      autoOpen: false,
      height:   180,
      width:    320,
      modal:    true,
      close:    function() {}
    });
    dialog.dialog("open");
  });
}

function loginToSeeLocation() {
  showDialogWindow({ f: 'location' })
  return false;
}

function loginToChat() {
  showDialogWindow({ f: 'chat' })
  return false;
}

function loginToCreateOffer() {
  showDialogWindow({ f: 'createoffer' })
  return false;
}

function updateResultslist() {
  $('#resultslist').html('');
  getSearchesForOffer($('#inputfield').val());
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
