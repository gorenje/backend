const throng = require('throng');
const app = require('./app.js');

const WORKERS = parseInt(process.env.WEB_CONCURRENCY || 3);
const LIFETIME = 1000 * 60 * (Math.ceil((Math.random()*20)) + 10);

console.log( "--- Lifetime became: " + (LIFETIME/(1000*60)) +
             " mins. Worker Count: " + WORKERS);

throng({
  workers:  WORKERS,
  lifetime: LIFETIME,
  grace:    5000,
  start:    start,
  master:   master
});

function master() {
  console.log("Started master, so what?")
}
function start() {
  app.start();
}
