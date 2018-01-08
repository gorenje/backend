var express = require('express')
var router  = express.Router()
var auth    = require('./auth')

var mongoose  = require('mongoose')
var Offer     = require('../models/Offer.js')
var vwhlpr    = require('../lib/helpers')
var qryHelper = require('../lib/query_helper')
var tracker   = require('../lib/tracker')

router.route('/')
  .get(auth.isAuthenticated, function(req, res, next) {
    var properties   = {}
    var keywords     = req.query.keywords
    var owner        = req.query.owner
    var not_owner    = req.query.not_owner
    var sw           = req.query.sw
    var ne           = req.query.ne
    var offer_id     = req.query._id
    var active_value = req.query.is_active

    if (keywords) {
      properties.keywords = { $in: keywords }
    } else {
      keywords = []
    }

    if (owner) {
      properties.owner = owner
    }
    if (not_owner) {
      properties.owner = { $ne: not_owner }
    }

    if (sw) {
      properties = qryHelper.locationBySwNe(properties, sw, ne);
    }

    if (offer_id) {
      properties._id = offer_id
    }

    if ( active_value ) {
      properties.isActive = (active_value === "true")
    }

    Offer.find(qryHelper.validate(properties), function(err, offers) {
      if (err) return next(err)
      sortedOffers = vwhlpr.stupidSort(offers, keywords)
      res.json(sortedOffers)
    })
  })

  .post(auth.isAuthenticated, function(req, res, next) {
    Offer.create(req.body, function (err, offer) {
      if (err) return next(err)
      tracker.sendTrackingEvent("offr",offer.trackingParams('create'),
        function(d,resp){
          res.json(offer)
        })
    })
  })

router.route('/:id/notify')
  .get(auth.isAuthenticated, function(req, res, next) {
    Offer.findOne({_id: req.params.id}, function (err, offer) {
      if (err) return next(err);
      if ( offer && offer.isActive ) {
        offer.findMatchingSearchesAndNotify(next, function(){
          res.json({status: 'ok'})
        });
      } else {
        res.json({status: 'ok'})
      }
    })
  })

router.route('/:id/set_active/:value')
  .get(auth.isAuthenticated, function(req, res, next) {
    Offer.findByIdAndUpdate(req.params.id,
      { isActive: req.params.value === "true" },
      function (err, offer) {
        if (err) return next(err)
        tracker.sendTrackingEvent("offr",offer.trackingParams('setact'),
          function(d,resp){
            res.json({status: 'ok'})
          })
      })
  })

router.route('/:id')
  .put(auth.isAuthenticated, function(req, res, next) {
    Offer.findByIdAndUpdate(req.params.id, req.body, function (err, offer) {
      if (err) return next(err)
      tracker.sendTrackingEvent("offr",offer.trackingParams('update'),
        function(d,resp){
          res.json(offer)
        })
    })
  })
  .delete(auth.isAuthenticated, function(req, res, next) {
    Offer.findByIdAndRemove(req.params.id, function (err, offer) {
      if (err) return next(err)
      tracker.sendTrackingEvent("offr",offer.trackingParams('delete'),
        function(d,resp){
          res.json(offer)
        })
    })
  })

module.exports = router
