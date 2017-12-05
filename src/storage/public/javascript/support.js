function setMatch(type,idstr) {
  $.ajax({
    url: '/store/set_match?type=' + type + '&id=' + idstr,
    method: 'get',
    dataType: 'json'
  }).done(function(data) {
    alert("Set Object Id " + idstr + " as " + type +
          " object for creating a match");
  });
}
