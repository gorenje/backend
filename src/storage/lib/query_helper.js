function geoBox(lng, lat, lngDelta,  latDelta) {
  return [ [lng - lngDelta/2.0, lat - latDelta/2.0],
           [lng + lngDelta/2.0, lat + latDelta/2.0] ];
}

function locationByGeoBox(properties, lng, lat, lngDelta, latDelta) {
  properties.location = {
    $geoWithin: { $box: geoBox(lng, lat, lngDelta, latDelta) }
  };
  return properties;
}

function locationFor(subject, properties) {
  return locationByGeoBox(properties,
                          subject.longitude(),      subject.latitude(),
                          subject.longitudeDelta(), subject.latitudeDelta());
}

function validate(properties) {
  properties.validuntil = { $gt: (new Date()).getTime() }
  properties.validfrom  = { $lt: (new Date()).getTime() }

  return properties;
}

function keyWordsAndOwner(subject, properties) {
  properties.keywords   = { $in: subject.keywords }
  properties.owner      = { $ne: subject.owner }

  return properties;
}


function lookupProps(subject, properties) {
  return locationFor(subject, keyWordsAndOwner(subject, validate(properties)));
}

exports.lookupProps      = lookupProps;
exports.validate         = validate;
exports.keyWordsAndOwner = keyWordsAndOwner;
exports.locationByGeoBox = locationByGeoBox;
