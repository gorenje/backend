var Kafka   = require('node-rdkafka')
var helpers = require('./helpers')

var producer     = null
var redisClient  = null
var appConfig    = null
var kafkaConf    = null
var disconnectCB = null

var setupProducer = function() {
  producer
    .once('shutdown-producer', function() {
      clearInterval(producer._intervals.drain)
      producer.flush(1000, function(){
        producer.disconnect()
      })
    })

    .once('ready', function(arg) {
      console.log('producer ready: ' + JSON.stringify(arg))
      producer._intervals.drain    = setInterval(drainRedis, 1000)
    })

    .once('disconnected', function(arg) {
      console.log('producer disconnected. ' + JSON.stringify(arg))
      for ( let intervalName in producer._intervals ) {
        clearInterval( producer._intervals[intervalName] )
      }
      if ( disconnectCB ) disconnectCB()
    })
}

var drainRedis = function() {
  var multi = redisClient.multi()

  for ( var i = 0; i < appConfig.BucketSize; i++ ) {
    multi.lpop(appConfig.RedisListName, function(err, result) {
      if ( result ) {
        try {
          producer.produce(appConfig.topics[0], -1, helpers.toKafkaMsg(result))
        } catch ( e ) {
          console.log("Exception, shutting down")
          console.log(e)
          producer.emit('shutdown-producer')
          redisClient.rpush(appConfig.RedisListName, result)
        }
      }
    })
  }

  multi.exec(function(err, replies){
    if ( err ) {
      console.log("Redis Errored Out with ...")
      console.log(err)
    }
  })
}

var shutdown = function() {
  producer.emit('shutdown-producer')
}

var setupConfig = function(redisClnt, appCfg, kafCfg, disCB) {
  redisClient  = redisClnt
  appConfig    = appCfg
  kafkaConf    = kafCfg

  setDisconnectCallback(disCB)
}

var reset = function() {
  producer     = null
  redisClient  = null
  appConfig    = null
  kafkaConf    = null
  disconnectCB = null
}

var setDisconnectCallback = function(disCB) {
  disconnectCB = disCB
}

var spinUp = function() {
  producer = new Kafka.Producer(kafkaConf, {})
  producer.setPollInterval(2000)
  producer._intervals = {}
  setupProducer()

  producer.connect()
}

exports.reset                 = reset
exports.spinUp                = spinUp
exports.shutdown              = shutdown
exports.setupConfig           = setupConfig
exports.setDisconnectCallback = setDisconnectCallback
