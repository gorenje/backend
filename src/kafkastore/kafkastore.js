require('dotenv').config()

console.log( "Connecting to zookeeper at: " + process.env.ZOOKEEPER_HOST)
console.log( "Connecting to redis at: "     + process.env.REDIS_TRACKING)

var redis       = require("redis")
var redisClient = null
var producer    = require('./lib/producer')
var helpers     = require('./lib/helpers')
var zkClient    = require('./lib/zookeeper')

var appConfig = {
  topics:        ["test"],
  RedisListName: "fubar",
  BucketSize:    3000,
}

// See https://github.com/edenhill/librdkafka/blob/0.11.1.x/CONFIGURATION.md
// for details on the configuration.
var kafkaConf = {
  'debug'                           : 'broker',
  'client.id'                       : 'producer1',
  'group.id'                        : 'kafkastore',
  'socket.keepalive.enable'         : true,
  'enable.auto.commit'              : true,
  'dr_cb'                           : true, // delivery report callback
  'queue.buffering.max.messages'    : Math.ceil(appConfig.BucketSize * 1.1),
  'queued.min.messages'             : appConfig.BucketSize*2,
  'queue.buffering.max.ms'          : 2500,
  'event_cb'                        : true
  // 'statistics.interval.ms'       : 30000,
}

kafkaConf["security.protocol"] = "plaintext"

var dropDead = function() {
  producer.setDisconnectCallback(null)
  producer.shutdown
}
process.once('SIGTERM', dropDead)
process.once('SIGINT',  dropDead)
process.once('SIGHUP',  dropDead)

var producerDisconnectedCB = function() {
  console.log( "Producer disconnected, we're reconnecting it" )
  producer.reset()
  createRedisAndSpinUpProducer()
}

var getBrokerListAndSpinUpProducer = function() {
  zkClient
    .getBrokerList()
    .then((broker_list) => {
      console.log("Broker list becomes: " + broker_list)
      kafkaConf["metadata.broker.list"] = broker_list
      producer.setupConfig(redisClient, appConfig,
                           kafkaConf, producerDisconnectedCB)
      producer.spinUp()
    })
    .catch((err) => {
      console.log("Caught Zookeeper error: " + err)
      setTimeout(getBrokerListAndSpinUpProducer, 5000)
    })
}

var createRedisAndSpinUpProducer = function() {
  if ( redisClient ) {
    redisClient.removeListener('error', () => {})
    redisClient.quit()
  }

  redisClient = redis.createClient({url: process.env.REDIS_TRACKING})

  redisClient.on('error', function (err) {
    console.log("Redis Error: " + err)
    process.exit(1)
  })

  redisClient.once("connect", function () {
    console.log("Redis Successfully Connected")
    getBrokerListAndSpinUpProducer()
  })
}

createRedisAndSpinUpProducer()
