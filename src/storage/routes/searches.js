var express = require('express')
var router  = express.Router()
var auth    = require('./auth')

var mongoose  = require('mongoose')
var Search    = require('../models/Search.js')
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
    var search_id    = req.query._id
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
      properties.location = {
        $geoWithin: { $box: [
          [ sw.longitude, sw.latitude ],
          [ ne.longitude, ne.latitude ]
        ]}
      }
    }
    if (search_id) {
      properties._id = search_id
    }

    if ( active_value ) {
      properties.isActive = (active_value === "true")
    }

    Search.find(qryHelper.validate(properties), function (err, searches) {
      if (err) return next(err)
      sortedSearches = vwhlpr.stupidSort(searches,keywords)
      res.json(sortedSearches)
    })
  })
  .post(auth.isAuthenticated, function(req, res, next) {
    Search.create(req.body, function (err, search) {
      if (err) return next(err)
      tracker.sendTrackingEvent("srch",search.trackingParams('create'),
        function(d,resp){
          res.json(search)
        })
    })
  })

router.route('/:id/notify')
  .get(auth.isAuthenticated, function(req, res, next) {
    Search.findOne({_id: req.params.id}, function (err, search) {
      if (err) return next(err);
      if ( search && search.isActive ) {
        search.findMatchingOffersAndNotify(next, function(){
          res.json({status: 'ok'})
        });
      } else {
        res.json({status: 'ok'})
      }
    })
  })

router.route('/:id/set_active/:value')
  .get(auth.isAuthenticated, function(req, res, next) {
    Search.findByIdAndUpdate(req.params.id,
      {isActive: req.params.value === "true"},
      function (err, search) {
        if (err) return next(err)
        tracker.sendTrackingEvent("srch",search.trackingParams('setact'),
          function(d,resp){
            res.json({status: 'ok'})
          })
      })
  })

router.route('/:id')
  .put(auth.isAuthenticated, function(req, res, next) {
    Search.findByIdAndUpdate(req.params.id, req.body, function (err, search) {
      if (err) return next(err)

      tracker.sendTrackingEvent("srch",search.trackingParams('update'),
        function(d,resp){
          res.json(search)
        })
    })
  })
  .delete(auth.isAuthenticated, function(req, res, next) {
    Search.findByIdAndRemove(req.params.id, function (err, search) {
      if (err) return next(err)

      tracker.sendTrackingEvent("srch",search.trackingParams('delete'),
        function(d,resp){
          res.json(search)
        })
    })
  })

module.exports = router
