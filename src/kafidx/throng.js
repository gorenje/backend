const throng = require('throng');
const app = require('./app.js');

const WORKERS = process.env.WEB_CONCURRENCY || 3;

throng({
  workers: WORKERS,
  lifetime: Infinity
}, start);

function start() {
  app.start();
}
