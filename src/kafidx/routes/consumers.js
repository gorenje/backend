var express = require('express');
var router  = express.Router();
var auth    = require('./auth')
var redis   = require('redis')

function sortData(a,b) {
  if ( a[0] < b[0] ) return -1;
  if ( a[0] > b[0] ) return 1;
  return 0;
}

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
        resolve(data.sort(sortData));
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
        html: "Error: "+err,
        id: "row" + req.params.db
      });
    })

    redisClient.on("connect", function () {
      redisClient.hget("_description", "name", function(err, result){
        if ( result ) {
          var link = "<a target='_blank' href='/consumers/" + req.params.db +
                     "/page'>" + result + "</a>"
          res.json({
            html: link,
            id: "row" + req.params.db
          });
        } else {
          res.json({
            html: "-",
            id: "row" + req.params.db
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
      redisClient.hmget("_description", ["name","desc","column","legend"],
                        function(err,result){
        if ( result ) {
          res.render('consumer-data', {
            name:        result[0],
            description: result[1],
            redisdb:     req.params.db,
            column:      result[2],
            legend:      result[3]
          })
        } else {
          res.render('consumer-error',{ error: 'nothing found' });
        }
      })
    });
  })

router
  .route("/:db/data")
  .get(auth.isAuthenticated, function(req, res, next) {
    var redisClient = redis.createClient({url: process.env.REDIS_URL +
                                               req.params.db})
    redisClient.on('error', function (err) {
      res.json({ data: [], lastupdate: err });
    })

    redisClient.on("connect", function () {
      redisClient.keys("*", (err, keys) => {
        if ( err ) {
          res.json({ data: [], lastupdate: err });
        } else {
          getData(redisClient,keys)
            .then( (data) => {
              res.json({
                data:        data,
                lastupdate:  new Date().toString()
              })
            })
            .catch( (err) => {
              res.json({ data: [], lastupdate: err });
            })
        }
      })
    })
  })

module.exports = router;
