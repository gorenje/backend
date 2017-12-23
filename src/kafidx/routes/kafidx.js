var express = require('express');
var router  = express.Router();
var auth    = require('./auth')

var crypto = require('crypto');

function md5(str) {
  str = str.toLowerCase().trim();
  var hash = crypto.createHash("md5");
  hash.update(str);
  return hash.digest("hex");
}

router.route("/")
      .get(auth.isAuthenticated, function(req, res, next) {
        res.render('kafidx', {
          session: req.session,
          ws_schema: process.env.WEB_SOCKET_SCHEMA || 'ws'
        });
      });

router.route('/getgroupid')
      .get(auth.isAuthenticated, function(req, res, next){
        req.session.kafka_group_id = "kafidx-" +
                                     md5(req.hostname).substring(0,5) + "-" +
                                     parseInt(Math.random()*1000)
        res.redirect("/kafidx")
      });

module.exports = router;
