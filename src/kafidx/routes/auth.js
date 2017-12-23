var passport = require('passport');
var BasicStrategy = require('passport-http').BasicStrategy;

passport.use(new BasicStrategy(
  function(username, password, callback) {
    if (username !== (process.env.API_USER || 'kafidx') ) {
      return callback(null, false)
    }
    if (password !== (process.env.API_PASSWORD || 'kafidx') ) {
      return callback(null, false)
    }
    return callback(null, username);
  }
));

exports.isAuthenticated = passport.authenticate('basic', { session : false });
