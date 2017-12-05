var passport = require('passport');
var BasicStrategy = require('passport-http').BasicStrategy;

passport.use(new BasicStrategy(
  function(username, password, callback) {
    if (username !== 'push') { return callback(null, false) }
    if (password !== 'push') { return callback(null, false) }
    return callback(null, username);
  } 
));

exports.isAuthenticated = passport.authenticate('basic', { session : false });
