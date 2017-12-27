var Client = require('node-rest-client').Client;

function matchFound(offer, search){
  if (!offer.is_valid() || !search.is_valid()) return;

  var client = new Client({user:     process.env.NOTIFY_API_USER,
                           password: process.env.NOTIFY_API_PASSWORD});

  var args = {
    data: {
      category: "match_found",
      offer: {
        device_id: offer.owner,
        title:     offer.text,
        id:        offer._id,
        lat:       offer.latitude(),
        lng:       offer.longitude(),
        latD:      offer.latitudeDelta(),
        lngD:      offer.longitudeDelta()
      },
      search: {
        device_id: search.owner,
        title:     search.text,
        id:        search._id,
        lat:       search.latitude(),
        lng:       search.longitude(),
        latD:      search.latitudeDelta(),
        lngD:      search.longitudeDelta()
      },
    },
    headers: { "Content-Type": "application/json" }
  };

  var endpoint = (process.env.NOTIFY_HOST || "http://localhost:3000")+"/notify";

  client.post(endpoint, args, function (data, response) {
    // parsed response body as js object
    console.log(data);
  });
}

exports.matchFound = matchFound;
