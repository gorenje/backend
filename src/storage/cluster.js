var cluster = require('cluster')
const app = require('./app.js');
const WORKERS = parseInt(process.env.WEB_CONCURRENCY || 3);

if ( cluster.isMaster ) {
  var workers = [];
  for (var i = 0; i < WORKERS; i += 1) {
    workers.push(cluster.fork());
  }

  cluster.on('online', function(worker) {
    console.log('Worker ' + worker.process.pid + ' is online');
  });

  cluster.on('exit', function(worker, code, signal) {
    console.log('Worker ' + worker.process.pid + ' died with code: ' +
                code + ', and signal: ' + signal);
    if ( signal !== 'SIGUSR1' ) {
      console.log('Starting a new worker');
      workers.push(cluster.fork());
    }
  });

  process.on('SIGTERM', function(){
    console.log("exiting " + process.pid);
    for(var idx=0; idx < workers.length; idx++) {
      if ( workers[idx] && workers[idx].process ) {
        console.log("destroying " + workers[idx].process.pid);
        workers[idx].destroy('SIGUSR1');
      }
    }
    setTimeout(function(){process.exit(0)}, 2000);
  });
} else {
  app.start()
}
