var zkClient = require('./lib/zookeeper')

console.log( "Starting Consumer: " + process.env.CONSUMER_NAME);

zkClient
  .getBrokerList()
  .then( (broker_list) => {
    console.log( "Broker list is: " + broker_list);
    switch(process.env.CONSUMER_NAME) {
      case "event_counter":
        require("./lib/event_counter").start(broker_list)
        break;
      case "stats_collector":
        require("./lib/stats_consumer").start(broker_list)
        break;
      case "metadata_counter":
        require("./lib/metadata_consumer").start(broker_list)
        break;
      default:
        console.log("No Consumer found, exiting....");
    }
  })
  .catch( (err) => {
    console.log( "Caught Zookeeper error: " + err);
    process.exit(1);
  })
