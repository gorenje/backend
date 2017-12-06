var express  = require('express');
var router   = express.Router();
var auth     = require('./auth');
var notifier = require('../lib/notifier')

var Offer     = require('../models/Offer.js')
var Search    = require('../models/Search.js')
var vwhlpr    = require('../lib/helpers.js')
var qryHelper = require('../lib/query_helper')

router
  .route("/offers")
  .get(auth.isAuthenticated, function(req, res, next) {
    var pageOptions = {
      page: parseInt(req.query.page || 0),
      limit: parseInt(req.query.limit || 200)
    }

    var srchQuery = {}
    if ( req.query.owner ) {
      srchQuery.owner = req.query.owner
    }

    Offer
      .find(srchQuery)
      .sort('owner')
      .skip( pageOptions.page * pageOptions.limit )
      .limit( pageOptions.limit )
      .exec(function(err, offers){
        Offer.count(srchQuery, function(error, count){
          pageOptions.total = count
          res.render('offers', { offers: offers, pageOptions: pageOptions  });
        });
      });
  });

router
  .route('/set_match')
  .get(auth.isAuthenticated, function(req, res, next) {
    if ( req.query.type == 'offer' ) {
      req.session.search_id = req.session.search_id;
      req.session.offer_id = req.query.id;
    } else {
      if ( req.query.type == 'search' ) {
        req.session.offer_id = req.session.offer_id;
        req.session.search_id = req.query.id;
      }
    }
    res.json({ status: 'ok'});
  });

router
  .route('/searches')
  .get(auth.isAuthenticated, function(req, res, next) {
    var pageOptions = {
      page: parseInt(req.query.page || 0),
      limit: parseInt(req.query.limit || 200)
    }

    var srchQuery = {}
    if ( req.query.owner ) {
      srchQuery.owner = req.query.owner
    }

    Search
      .find(srchQuery)
      .sort('owner')
      .skip( pageOptions.page * pageOptions.limit)
      .limit( pageOptions.limit )
      .exec( function(err, searches){
        Search.count(srchQuery, function(error, count){
          pageOptions.total = count
          res.render('searches',{searches: searches, pageOptions: pageOptions});
        })
      });
  });

router.route('/matches')
  .get(auth.isAuthenticated, function(req, res, next) {
    if ( req.session.search_id && req.session.offer_id ) {
      Search.find({_id: req.session.search_id}, function(err, searches){
        if (err) return next(err);
        Offer.find({_id: req.session.offer_id}, function(err, offers){
          if (err) return next(err);
          res.render('matches', { searches: searches, offers: offers });
        });
      });
    } else {
      if ( req.session.search_id ) {
        res.redirect("/store/offers");
      } else {
        res.redirect("/store/searches");
      }
    }
  })
  .post(auth.isAuthenticated, function(req, res, next) {
    Search.find({_id: req.body.search_id}, function(err, searches){
      if (err) return next(err);
      Offer.find({_id: req.body.offer_id}, function(err, offers){
        if (err) return next(err);
        notifier.matchFound(offers[0], searches[0]);
        res.render('done');
      });
    });
  });

router
  .route('/delete/offer/:id')
  .get(auth.isAuthenticated, function(req, res, next) {
    Offer.remove({_id: req.params.id}, function(err, post){});
    res.redirect(req.headers.referer || "/store/offers");
  });

router
  .route('/delete/search/:id')
  .get(auth.isAuthenticated, function(req, res, next) {
    Search.remove({_id: req.params.id}, function(err, post){});
    res.redirect(req.headers.referer || "/store/searches");
  });

router
  .route('/update/subject/:id')
  .post(auth.isAuthenticated, function(req, res, next) {
    for ( prop in {isMobile: 1, showLocation: 1, allowContacts: 1}) {
      req.body[prop] = req.body[prop] || false
    }
    req.body.keywords =
      req.body.keywords.toLowerCase().split(",").map((a) => {return a.trim()});

    var properties = { _id: req.params.id }
    Offer.find(properties, function(err, offers){
      if ( offers.length > 0 ) {
        req.body.location = JSON.parse(JSON.stringify(offers[0])).location;
        req.body.location.dimension.latitudeDelta  = req.body.latDelta;
        req.body.location.dimension.longitudeDelta = req.body.lngDelta;
        req.body.location.radius = req.body.radius;
        delete(req.body["latDelta"]);
        delete(req.body["lngDelta"]);
        delete(req.body["radius"]);

        Offer.update({ _id: req.params.id }, req.body, function (err, post) {});
        res.redirect('/store/details/' + req.params.id)
      } else {
        Search.find(properties, function(err, searches){
          if (searches.length > 0 ){
            req.body.location =
                JSON.parse(JSON.stringify(searches[0])).location;
            req.body.location.dimension.latitudeDelta  = req.body.latDelta;
            req.body.location.dimension.longitudeDelta = req.body.lngDelta;
            req.body.location.radius = req.body.radius;
            delete(req.body["latDelta"]);
            delete(req.body["lngDelta"]);
            delete(req.body["radius"]);

            Search.update({ _id: req.params.id },
              req.body, function (err, post) {});
            res.redirect('/store/details/' + req.params.id)
          }
        });
      }
    });
  });

router
  .route('/details/:id')
  .get(auth.isAuthenticated, function(req, res, next) {
    if ( req.params.id ) {
      var properties = { _id: req.params.id }
      Offer.findOne(properties, function(err, offer){
        if ( offer ) {
          if ( offer.location.radius ) {
             res.render('details_circle', { obj: offer });
          } else {
             res.render('details', { obj: offer });
          }
        } else {
          Search.findOne(properties, function(err, search){
            if (search ){
              if ( search.location.radius ) {
                res.render('details_circle', { obj: search });
              } else {
                res.render('details', { obj: search });
              }
            } else {
              res.render('noresult');
            }
          });
        }
      });
    } else {
      res.render('noresult');
    }
  });

router
  .route('/geo')
  .get(auth.isAuthenticated, function(req, res, next) {
    var lng = parseFloat(req.query.lg);
    var lat = parseFloat(req.query.lt);

    Search.find({owner: req.query.di, isMobile: true}, function(err, searches){
      var opers = searches.map( (srch) => {
        return { updateOne: { filter: { _id: srch._id },
                 update: srch.cloneReplacingLngLat(lng,lat) } };
      });
      if ( opers.length > 0 ) { Search.bulkWrite(opers, function(err) {}) }

      searches.forEach( (srch) => {
        var properties =
          qryHelper.keyWordsAndOwner(srch, qryHelper.validate({isActive:true}));

        properties = qryHelper.locationByGeoBox(properties, lng, lat,
                                                srch.longitudeDelta(),
                                                srch.latitudeDelta());

        Offer.find(properties, function(err, offers) {
          if (err) return next(err)
          offers.forEach( (offer) => {
            if ( offer.is_point_within_range(lng, lat) ) {
              notifier.matchFound(offer, srch);
            }
          });
        });
      });
    });

    Offer.find({owner: req.query.di, isMobile: true}, function(err, offers){
      var opers = offers.map( (offr) => {
        return { updateOne: { filter: { _id: offr._id },
                 update: offr.cloneReplacingLngLat(lng, lat) } };
      });
      if ( opers.length > 0 ) { Offer.bulkWrite(opers, function(err) {}) }

      offers.forEach( (offer) => {
        var properties =
          qryHelper.keyWordsAndOwner(offer,qryHelper.validate({isActive:true}));

        properties = qryHelper.locationByGeoBox(properties, lng, lat,
                                                offer.longitudeDelta(),
                                                offer.latitudeDelta());

        Search.find(properties, function(err, searches) {
          if (err) return next(err)
          searches.forEach( (srch) => {
            if ( srch.is_point_within_range(lng, lat) ) {
              notifier.matchFound(offer, srch);
            }
          });
        });
      });
    });

    res.json({status: "donegeo"});
  });

module.exports = router;
