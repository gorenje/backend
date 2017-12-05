var dns = require('dns')

var getBrokerList = function(kafka_host_and_port) {
  var kafka_hostname = kafka_host_and_port.split(/:/)[0]
  var kafka_portnum  = kafka_host_and_port.split(/:/)[1] || '9092'

  return new Promise((resolve, reject) => {
    dns.lookup(kafka_hostname, { all: true }, function(err,addresses) {
      if (err) {
        console.log(err)
        console.log("Failed to lookup kafka brokers")
        reject(err)
      }

      var broker_list = []
      for ( let idx in addresses ) {
        broker_list.push(addresses[idx].address + ":" + kafka_portnum)
      }

      resolve(broker_list.sort())
    })
  });
}

exports.getBrokerList = getBrokerList;
