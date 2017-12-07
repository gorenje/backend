var fs    = require('fs')
var Kafka = require('node-rdkafka')
var ip    = require('ip-address')
var qs    = require('qs')
var util  = require('util')

var helpers     = require('./helpers')
var BigInteger  = require('jsbn').BigInteger

function msgToHash(str) {
  var type_meta_params = str.split(" ");

  var result    = qs.parse(type_meta_params[1]);
  result.ts     = result.ts
  result.type   = type_meta_params[0];
  result.ip_dot = ip.Address6.fromBigInteger(new BigInteger(result.ip,16))
                    .correctForm();
  result.params = type_meta_params[2]

  return util._extend(qs.parse(type_meta_params[2]), result);
}

function streamTo(websocket, groupid) {
  helpers
    .getBrokerList()
    .then((broker_list) => {
      streamToGettingFrom(websocket, groupid, broker_list.sort())
    })
    .catch((err) => {
      console.log("Something went wrong: " + err);
      process.exit(1)
    })
}

function streamToGettingFrom(websocket, groupid, kafka_broker_list) {
  var kafkaConf = {
    'group.id': groupid,
    'socket.keepalive.enable': true,
    'enable.auto.commit': true,
    // 'debug': 'all',
  };

  console.log("Configuring consumer, connecting to " + kafka_broker_list);

  var topics = ["test"];

  console.log("Setting up kafka")
  kafkaConf["security.protocol"] = "plaintext"
  kafkaConf["metadata.broker.list"] = kafka_broker_list

  var consumer = new Kafka.KafkaConsumer(kafkaConf, {
    'auto.offset.reset': 'beginning'
  });

  consumer
    .on('ready', function() {
      console.log( "Consumer Ready" );
      consumer.subscribe(topics);
      consumer.consume();
    })

    .on('error', function(err) {
      console.log( "Consumer Error" );
      console.log(err);
      websocket.terminate();
    })

    .on('data', function(data) {
      var result = msgToHash(data.value.toString());
      result.topic       = data.topic
      result._offset_    = data.offset
      result._msgvalue_  = data.value.toString();
      result._partition_ = data.partition
      result._msgkey_    = data.key

      websocket.send(JSON.stringify(result), function(err){
        if ( err ) {
          console.log( "Websocket error, closing" );
          websocket.terminate();
          consumer.disconnect();
        }
      });
    })

    .connect();
}

exports.streamTo = streamTo;
