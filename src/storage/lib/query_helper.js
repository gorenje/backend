var geolib    = require('geolib');

function locationByCenterSphere(properties, lng, lat, radius) {
  // assuming radius is in meters, not kilometers nor in bananas.
  // 6,378.1 km is the equatorial radius of the Earth
  properties.location = {
    $geoWithin: { $centerSphere: [ [parseFloat(lng), parseFloat(lat)],
                                   parseFloat(radius) / 6378100] }
  };
  return properties;
}

function locationBySwNe(properties, sw, ne) {
  var points = [
    { latitude: parseFloat(sw.latitude), longitude: parseFloat(sw.longitude) },
    { latitude: parseFloat(ne.latitude), longitude: parseFloat(ne.longitude) }
  ];

  var diagonal_in_meters = geolib.getPathLength(points);
  var center             = geolib.getCenter(points);

  return locationByCenterSphere(properties, center.longitude, center.latitude,
                                Math.sqrt(2*((diagonal_in_meters/2)**2))/2);
}

function locationFor(subject, properties) {
  return locationByCenterSphere(properties, subject.longitude(),
                                subject.latitude(), subject.radius());
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

exports.lookupProps            = lookupProps;
exports.validate               = validate;
exports.keyWordsAndOwner       = keyWordsAndOwner;
exports.locationByCenterSphere = locationByCenterSphere;
exports.locationBySwNe         = locationBySwNe;
