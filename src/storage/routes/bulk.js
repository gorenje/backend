var express = require('express')
var router  = express.Router()
var auth    = require('./auth')

var mongoose  = require('mongoose')
var Offer     = require('../models/Offer.js')
var vwhlpr    = require('../lib/helpers.js')
var qryHelper = require('../lib/query_helper')

router.route('/offers/:owner')
  .get(auth.isAuthenticated, function(req, res, next) {
    var comma = "";
    res.write('{ "version": "1.0", "data": [')

    Offer.find({ owner: req.params.owner })
      .cursor()
      .on('data', function(data) {
        res.write(comma)
        res.write(JSON.stringify(data));
        comma = ","
      })
      .on('end', function() {
        res.end("]}")
      })
  })
  .delete(auth.isAuthenticated, function(req, res, next) {
    if (req.params.owner){
      Offer.remove({ owner: req.params.owner }, function(err, offers) {
        if (err) return next(err);
        res.json({status: "ok"})
      });
    } else {
      res.json({status: "ok"})
    }
  })
;

router.route('/offers')
  .post(auth.isAuthenticated, function(req, res, next) {
    Offer.insertMany(req.body.new_offers, function(err, data){
      if (err) return next(err);

      var opers = req.body.old_offers.map( (offr) => {
        return { updateOne: { filter: { _id: offr._id }, update: offr } };
      });

      if ( req.body.remove_offers && req.body.remove_offers.length > 0 ) {
        var ids = req.body.remove_offers.map( offr => { return offr._id; });
        opers = opers.concat([ {deleteMany: {filter: {_id: {$in: ids}}}} ]);
      }

      if ( opers.length > 0 ) {
        Offer.bulkWrite(opers, function(err, result){
          if (err) return next(err);
          res.json({status: "ok"})
        })
      } else {
        res.json({status: "ok"})
      }
    })
  })

router.route('/notify_searchers/:owner')
  .get(auth.isAuthenticated, function(req, res, next) {
    var properties = { owner: req.params.owner, isActive: true }

    Offer.find(qryHelper.validate(properties))
      .cursor()
      .on('data', function(offer){
        offer.findMatchingSearchesAndNotify(next, function(){});
      })
      .on('end', function(){
        res.json({status: "ok"})
      })
  });

module.exports = router
