var express = require('express');
var router = express.Router();

var redis = require("redis"),
    client = redis.createClient({url: process.env.REDIS_URL ||
                                 "redis://localhost:6379/6"});

router.get('*', function(req, res, next) {
  res.json({status: 'ok'})

  var msg = [];

  var remoteip = null;

  if ( req.headers['x-push-ip'] ) {
    remoteip = req.headers['x-push-ip']
  }
  if ( req.headers['x-forwarded-for'] && !remoteip) {
    remoteip = req.headers['x-forwarded-for'].split(",")[0].trim()
  }
  if ( req.headers['x-real-ip'] && !remoteip) {
    remoteip = req.headers['x-real-ip']
  }

  msg.push(remoteip || req.connection.remoteAddress || req.clientIp||'0.0.0.0');
  msg.push((new Date).getTime());
  msg.push(req.hostname || req.socket.server.address().address || "nohost")
  msg.push(process.env.POD_IP || "nopod")
  msg.push(req._parsedOriginalUrl.pathname || 'p')
  msg.push(req._parsedOriginalUrl.query || 'e')

  msg.push(req.headers["user-agent"])

  client.rpush("fubar", msg.join(" "), function(err, response){});
});

module.exports = router;
