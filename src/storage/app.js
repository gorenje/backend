require('dotenv').config()

// load mongoose package
var mongoose = require('mongoose');

// Use native Node promises
mongoose.Promise = global.Promise;

// connect to MongoDB
mongoose.connect(process.env.MONGOHQ_URL || 'mongodb://localhost/push')
        .then(() =>  console.log('connection succesful'))
        .catch((err) => {
          console.error(err);
          process.env.NO_MONGO_CONNECTION = true;
        });

// original app.js starts here
var express      = require('express');
var session      = require('client-sessions');
var path         = require('path');
var favicon      = require('serve-favicon');
var logger       = require('morgan');
var passport     = require('passport');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');

var index    = require('./routes/index');
var offers   = require('./routes/offers');
var searches = require('./routes/searches');
var store    = require('./routes/store');
var chat     = require('./routes/chat');
var bulk     = require('./routes/bulk');
var channels = require('./routes/channels');

var app = express();

app.set('port', (process.env.PORT || 5000));
app.disable('etag');

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('combined'));
//app.use(bodyParser({limit: '50mb'}));
app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(passport.initialize());
app.use(session({
  cookieName: 'session',
  secret: process.env.COOKIE_SECRET || 'nogreatsecret',
  duration: 24 * 60 * 60 * 1000,
  activeDuration: 1000 * 60 * 5
}));

app.use('/',         index);
app.use('/offers',   offers);
app.use('/searches', searches);
app.use('/store',    store);
app.use('/chat',     chat);
app.use('/bulk',     bulk);
app.use('/channels', channels);

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
