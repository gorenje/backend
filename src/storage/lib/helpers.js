function is_valid(subject){
  return subject.validuntil > subject.validfrom &&
         subject.validuntil >= (new Date()).getTime() &&
         subject.validfrom  <= ((new Date()).getTime() + 60000) &&
         subject.isActive;
}

function compareRank(a, b) {
  if (a.rank < b.rank) return 1
  if (a.rank > b.rank) return -1
  var akw = a.keywords.join(' ')
  var bkw = b.keywords.join(' ')
  if (akw < bkw) return -1
  if (akw > bkw) return 1
  return 0
}

function stupidSort(subjects, keywords) {
  return subjects.map((obj) => {
    var ranked
    ranked=JSON.parse(JSON.stringify(obj))
    ranked.rank=0
    ranked.isKeyword=[]
    obj.keywords.map((keyword, i) => {
      var index = keywords.indexOf(keyword)
      if (index >= 0) {
        ranked.rank++
        ranked.isKeyword.push(i)
      }
    })
    return ranked
  })
  .sort(compareRank)
}

function generate_polygon(subject) {
  var lngDelta = subject.longitudeDelta() / 2.0;
  var latDelta = subject.latitudeDelta() / 2.0;

  var lat = subject.latitude();
  var lng = subject.longitude();

  return [
    { latitude: lat + latDelta, longitude: lng - lngDelta },
    { latitude: lat + latDelta, longitude: lng + lngDelta },
    { latitude: lat - latDelta, longitude: lng + lngDelta },
    { latitude: lat - latDelta, longitude: lng - lngDelta }
  ]
}

exports.is_valid = is_valid;
exports.stupidSort = stupidSort;
exports.generate_polygon = generate_polygon;
