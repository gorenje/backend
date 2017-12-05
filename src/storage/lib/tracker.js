var Client = require('node-rest-client').Client;
var querystring = require('qs');

function sendTrackingEvent(name, data, callback){
  var client = new Client();

  var args = {
    data: data,
    headers: { "Content-Type": "application/json" }
  };

  var endpoint = (process.env.TRACKER_HOST || "http://localhost:3000")+
                 "/w/" + name + "?" + querystring.stringify(data);

  client.get(endpoint, callback);
}

exports.sendTrackingEvent = sendTrackingEvent;
