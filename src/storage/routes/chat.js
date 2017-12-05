var express = require('express');
var router  = express.Router();
var auth    = require('./auth')

var Offer    = require('../models/Offer.js')
var Search   = require('../models/Search.js')
var vwhlpr   = require('../lib/helpers')
var mongoose = require('mongoose')

router.route("/")
  .get(auth.isAuthenticated, function(req, res, next) {
    if ( req.query._id ) {
      var properties = { _id: req.query._id }
      Offer.find(properties, function(err, offers){
        if ( offers.length > 0 ) {
          res.json(offers);
        } else {
          Search.find(properties, function(err, searches){
            if ( searches.length > 0 ) {
              res.json(searches);
            } else {
              res.json({})
            }
          });
        }
      });
    } else {
      res.json({})
    }
});

router.route("/byids")
  .get(auth.isAuthenticated, function(req, res, next) {
    var ids = []
    if (typeof(req.query._id) === "string") {
      if ( req.query._id.indexOf("_") > 0 ) {
        ids = req.query._id.split("_")
      } else {
        ids = [req.query._id]
      }
    } else {
      ids = req.query._id
    }

    ids = ids.filter( (value) => {
      return mongoose.Types.ObjectId.isValid(value);
    });

    var result = { offers: [], searches: [] }

    var properties = { }
    properties._id = { $in: ids }

    Offer.find(properties, function(err, offers){
      Search.find(properties, function(err, searches){
        result.offers = vwhlpr.stupidSort(offers,
          searches.length > 0 ? searches[0].keywords : []);

        result.searches = vwhlpr.stupidSort(searches,
          offers.length > 0 ? offers[0].keywords : []);

        res.json(result);
      });
    });
  });

module.exports = router;
