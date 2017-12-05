require('dotenv').config()

var redis = require("redis"),
    client = redis.createClient({url: process.env.REDIS_URL ||
                                            "redis://localhost:6379?db=6"});
client.on("error", function (err) {
  console.log("Error " + err);
  process.exit(1);
});

client.on("connect", function () {
  console.log("Redis Successfully Connected");
});

// original app.js starts here
var express      = require('express');
var session      = require('client-sessions');
var path         = require('path');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var requestIp    = require('request-ip');

var index    = require('./routes/index');
var tracking = require('./routes/tracking');

var app = express();

app.set('port', (process.env.PORT || 5000));
app.disable('etag');

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(logger('combined'));
app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(requestIp.mw())
app.use(session({
  cookieName: 'session',
  secret: process.env.COOKIE_SECRET || 'nogreatsecret',
  duration: 24 * 60 * 60 * 1000,
  activeDuration: 1000 * 60 * 5
}));

app.use('/',  index);
app.use('/t', tracking);

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
  app.listen(app.get('port'), function() {
    console.log('Node app is running on port', app.get('port'));
  });
}

// this is is used by mocha for testing.
function get_app() {
  return app;
}

exports.start = start;
exports.get_app = get_app;
