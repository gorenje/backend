require('dotenv').config()

var Kafka = require('node-rdkafka');
var redis = require("redis");

var redisClient = redis.createClient({url: process.env.REDIS_CONSUMER});

redisClient.on('error', function (err) {
  console.log("Redis Error: " + err);
  shutdown();
  process.exit(1);
});

redisClient.on("connect", function () {
  console.log("Redis Successfully Connected");
});

var consumer = null;

var watchDog = function() {
  console.log("---------- Current Counts " + (new Date()) + " -------------");
  redisClient.keys("*", function(err, keys) {
    for ( var idx in keys ) {
      let key = keys[idx]
      redisClient.get(key, function(err, cnt) {
        console.log("[Event] " + key + ": " + cnt );
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

var shutdown = function() {
  console.log("Shutting down consumer, last update...");
  consumer.disconnect();
}

function start(broker_list) {
  var kafkaConf = {
    'group.id': 'event_counter',
    'socket.keepalive.enable': true,
    'enable.auto.commit': true,
    // 'debug': 'all',
  };

  console.log("!!! Configuring Events Counter Consumer");

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
    })

    .on('error', function(err) {
      console.log(err);
      process.exit(1);
    })

    .on('data', function(data) {
      var type_meta_params = data.value.toString().split(" ");
      redisClient.incr(type_meta_params[0], function(err, response){});
    })

    .on('disconnected', function(arg) {
      console.log('consumer disconnected. ' + JSON.stringify(arg));
      process.exit(0);
    });

  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
  process.once('SIGHUP', shutdown);

  consumer.connect();
}

exports.start = start;
