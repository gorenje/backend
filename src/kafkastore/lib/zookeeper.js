var zookeeper = require('node-zookeeper-client');

var getBrokerList = function(host_with_port) {
  return new Promise( (resolve,reject) => {
    var client = zookeeper.createClient(host_with_port);

    client.on("connected", function() {
      client.getChildren("/brokers/ids", function(err,data) {
        if (err) return reject(err)

        var brokerids = data.toString('utf8').split(/,/)
        var promises = []

        for ( var idx in brokerids ) {
          promises.push(new Promise( (rs,rj) => {
            client.getData("/brokers/ids/" + brokerids[idx], function(err,data){
              if (err) return rj(err)

              let tmp = JSON.parse(data.toString('utf8'))
              rs(tmp.host + ":" + tmp.port)
            })
          }))
        }

        Promise
          .all(promises)
          .then((broker_list) => {
            client.close()
            resolve(broker_list.sort())
          })
      })
    })

    client.connect()
  })
}

exports.getBrokerList = getBrokerList
