var geoip = require('geoip-lite')
var dns   = require('dns')
var ip    = require('ip-address')
var qs    = require('qs')

var DeviceDetector = require('device-detector')
var DefaultGeo     = { country: 'XX', city: 'XX' }

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

  var eventType    =
    path.split("/").filter( function(w) { return w.length > 0 } ).pop() || "/"

  var geoLU        = geoip.lookup(ipStr) || DefaultGeo
  var nowTstamp    = (new Date()).getTime()
  var metaData     = DeviceDetector.parse(userAgent)
  delete metaData["userAgent"]

  var ipNum = (new ip.Address4(ipStr)).bigInteger() ||
                           (new ip.Address6(ipStr)).bigInteger()

  metaData.host    = hostName
  metaData.pod     = podIp
  metaData.ts      = entryTStamp
  metaData.ip      = ipNum.toRadix(16)
  metaData.klag    = nowTstamp - parseInt(entryTStamp)
  metaData.country = geoLU.country
  metaData.city    = geoLU.city

  result.push(eventType)
  result.push(qs.stringify(metaData))
  result.push(query)

  return new Buffer(result.join(" "))
}

exports.toKafkaMsg    = toKafkaMsg
