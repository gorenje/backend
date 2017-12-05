var geoip = require('geoip-lite')
var dns   = require('dns')
var ip    = require('ip-address')
var qs    = require('qs')

var DeviceDetector = require('device-detector')
var DefaultGeo     = { country: 'XX', city: 'XX' }

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
  })
}

var toKafkaMsg = function(redisStr) {
  var result       = []

  var stuff        = redisStr.split(" ")

  var ipStr        = stuff.shift()
  var entryTStamp  = stuff.shift()
  var hostName     = stuff.shift()
  var podIp        = stuff.shift()
  var path         = stuff.shift()
  var query        = stuff.shift()
  var userAgent    = stuff.join(" ")

  var eventType    = path.split("/")
                         .filter( function(w) { return w.length > 0 } ).pop()
  var geoLU        = geoip.lookup(ipStr) || DefaultGeo
  var nowTstamp    = (new Date()).getTime()
  var metaData     = DeviceDetector.parse(userAgent)
  delete metaData["userAgent"]

  metaData.host    = hostName
  metaData.pod     = podIp
  metaData.ts      = entryTStamp
  metaData.ip      = (new ip.Address6(ipStr)).bigInteger().toRadix(16)
  metaData.klag    = nowTstamp - parseInt(entryTStamp)
  metaData.country = geoLU.country
  metaData.city    = geoLU.city

  result.push(eventType)
  result.push(qs.stringify(metaData))
  result.push(query)

  return new Buffer(result.join(" "))
}

exports.toKafkaMsg    = toKafkaMsg
exports.getBrokerList = getBrokerList
