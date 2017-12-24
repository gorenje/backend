var express = require('express');
var router  = express.Router();
var auth    = require('./auth')
var redis   = require('redis')

function getData(redisClient, keys) {
  return new Promise( (resolve,reject) => {
    promises = []

    for ( var idx in keys ) {
      if ( keys[idx] == "_description" ) continue;
      promises.push(new Promise((rs,rj) => {
        let key = keys[idx]
        redisClient.get(key, function(err, cnt) {
          if (err) rj(err);
          rs([key, cnt])
        })
      }))
    }

    Promise
      .all(promises)
      .then((data) => {
        redisClient.quit()
        resolve(data);
      })
      .catch((err) => {
        reject(err);
      })
  })
}


router
  .route("/")
  .get(auth.isAuthenticated, function(req, res, next) {
    res.render('consumers');
  });

router
  .route("/:db/json")
  .get(auth.isAuthenticated, function(req, res, next) {
    var redisClient = redis.createClient({url: process.env.REDIS_URL +
                                               req.params.db})
    redisClient.on('error', function (err) {
      res.json({
        tablerow: "<tr><td>" + req.params.db + "</td><td>Nothing</td></tr>"
      });
    })

    redisClient.on("connect", function () {
      redisClient.hget("_description", "name", function(err, result){
        if ( result ) {
          var link = "<a target='_blank' href='/consumers/" + req.params.db +
                     "/page'>" + result + "</a>"
          res.json({
            tablerow: "<tr><td>" + req.params.db +"</td><td>"+link+"</td></tr>"
          });
        } else {
          res.json({
            tablerow: "<tr><td>" + req.params.db +"</td><td>-</td></tr>"
          });
        }
        redisClient.quit()
      })
    });
  });

router
  .route("/:db/page")
  .get(auth.isAuthenticated, function(req, res, next) {
    var redisClient = redis.createClient({url: process.env.REDIS_URL +
                                               req.params.db})
    redisClient.on('error', function (err) {
      res.render('consumer-error', { error: 'redis error' });
    })

    redisClient.on("connect", function () {
      redisClient.hmget("_description", ["name","desc"], function(err,result){
        if ( result ) {
          name = result[0]
          desc = result[1]

          redisClient.keys("*", (err, keys) => {
            getData(redisClient,keys)
              .then( (data) => {
                res.render('consumer-data', {
                  name:        name,
                  description: desc,
                  data:        data
                })
              })
              .catch( (err) => {
                res.render('consumer-error', { error: err });
              })
            })
        } else {
          res.render('consumer-error',{ error: 'nothing found' });
        }
      })
    });
  })

module.exports = router;
