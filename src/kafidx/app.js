require('dotenv').config()

// original app.js starts here
var express      = require('express');
var session      = require('client-sessions');
var path         = require('path');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var WebSocket    = require('ws');
var url          = require('url');

var index  = require('./routes/index');
var kafidx = require('./routes/kafidx');

var http = require('http');
var app = express();
var KafkaStreamer = require('./lib/kafka_streamer')

var server = http.createServer(app);
var wss = new WebSocket.Server({ server });

function heartbeat() {
  this.isAlive = true;
}

wss.on('connection', function connection(ws, req) {
  const location = url.parse(req.url, true);
  if ( location.pathname === "/kafidx/socket" ) {
    ws.isAlive = true;
    ws.on('pong', heartbeat);
    KafkaStreamer.streamTo(ws, location.query.gid)
  }
});

const interval = setInterval(function ping() {
  wss.clients.forEach(function each(ws) {
    if (ws.isAlive === false) return ws.terminate();

    ws.isAlive = false;
    ws.ping('', false, true);
  });
}, 30000);

app.set('port', (process.env.PORT || 5000));
app.disable('etag');

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger('combined'));
app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(session({
  cookieName: 'session',
  secret: process.env.COOKIE_SECRET || 'nogreatsecret',
  duration: 24 * 60 * 60 * 1000,
  activeDuration: 1000 * 60 * 5
}));

app.use('/',  index);
app.use('/kafidx', kafidx);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

// This function is used for throng
function start() {
  server.listen(app.get('port'), function() {
    console.log('Node app is running on port', app.get('port'));
  });
}

exports.start = start;
