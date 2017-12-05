function toggleNotificationReadState(notid) {
  $.ajax({
    url: "/notifications/" + notid + "/toggleread",
    method: "get",
    data: {},
    dataType: 'json'
  }).done(function(data){
    if ( data.status === "hide" ) {
      $("#notrow_"+notid).hide();
    } else {
      $("#notrow_"+notid).removeClass().addClass(data.css_class);
      $("#notrow_"+notid).html(data.html)
    }
  });
}

function deleteNotification(notid) {
  $.ajax({
    url: "/notifications/" + notid + "/delete",
    method: "get",
    data: {},
    dataType: 'json'
  }).done(function(data){
    $("#notrow_"+notid).hide();
  });
}
