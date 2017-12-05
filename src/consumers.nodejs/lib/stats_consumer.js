require('dotenv').config()

var Kafka = require('node-rdkafka');
var redis = require("redis");
var qs    = require('qs');

var redisClient = redis.createClient({url: process.env.REDIS_CONSUMER});

redisClient.on('error', function (err) {
  console.log("Redis Error: " + err);
  shutdown()
  process.exit(1);
});

redisClient.on("connect", function () {
  console.log("Redis Successfully Connected");
});

var klagBucket    = []
var tsBucket      = []
var eventsCounter = 0;
var consumer      = null;

var avg = function(store) {
  var calc = 0;
  for (var x in store) { calc += store[x]; }
  return (calc / store.length);
}

var watchDog = function() {
  console.log("---------- Current Stats " + (new Date()) + " -------------");
  redisClient.keys("*", function(err, keys) {
    for ( var idx in keys ) {
      let key = keys[idx]
      redisClient.get(key, function(err, cnt) {
        console.log("[Stats] " + key + ": " + cnt );
      })
    }
  })
}
var watchDogInterval = null;

var connectionTimeout = function() {
  console.log("Triggering a shutdown, took too long to connect to kafka");
  process.exit(1);
}
var connectionTimeoutInterval = setInterval(connectionTimeout, 45000);

var computeStats = function() {
  var numEventsSeen = eventsCounter;
  eventsCounter = 0;

  redisClient.get("klag", function(err, value) {
    if (err) return;
    klagBucket.push(parseInt(value) || 0);
    redisClient.set("klag", Math.ceil(avg(klagBucket)), function(err, response){
      if (err) return;
      klagBucket = [];
    });
  });

  redisClient.get("tsavg", function(err, value) {
    if (err) return;
    tsBucket.push(parseInt(value) || 0);
    redisClient.set("tsavg", Math.ceil(avg(tsBucket)), function(err, response){
      if (err) return;
      tsBucket = [];
    });
  });

  redisClient.get("totaleventsseen", function(err, value) {
    redisClient.set("totaleventsseen", (parseInt(value) || 0) + numEventsSeen,
                    function(err, response){})
  });
}
var computeStatsInterval = null;

var shutdown = function() {
  console.log("Shutting down consumer, last update...");
  clearInterval(computeStatsInterval);
  consumer.disconnect();
}

function start(broker_list) {
  var kafkaConf = {
    'group.id': 'stats_consumer',
    'socket.keepalive.enable': true,
    'enable.auto.commit': true,
    // 'debug': 'all',
  };

  console.log( "Configuring consumer" );

  var topics = ["test"];

  console.log("Setting up kafka")
  kafkaConf["security.protocol"] = "plaintext"
  kafkaConf["metadata.broker.list"] = broker_list;

  consumer = new Kafka.KafkaConsumer(kafkaConf, {
    'auto.offset.reset': 'beginning'
  });

  consumer
    .on('ready', function() {
      console.log( "Consumer Ready" );
      clearInterval(connectionTimeoutInterval);

      consumer.subscribe(topics);
      consumer.consume();
      watchDogInterval = setInterval(watchDog, 2000);
      computeStatsInterval = setInterval(computeStats, 5000);
    })

    .on('error', function(err) {
      console.log(err);
      process.exit(1)
    })

    .on('data', function(data) {
      var type_meta_params = data.value.toString().split(" ");
      var metaData = qs.parse( type_meta_params[1] );

      eventsCounter++;
      klagBucket.push(parseInt(metaData.klag));
      tsBucket.push((new Date()).getTime() - parseInt(metaData.ts));
    })

    .on('disconnected', function(arg) {
      console.log('consumer disconnected. ' + JSON.stringify(arg));
      computeStats();
      process.exit(0);
    });

  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
  process.once('SIGHUP', shutdown);

  consumer.connect();
}

exports.start = start;
