var express  = require('express')
var router   = express.Router()
var auth     = require('./auth')

var mongoose = require('mongoose')
var Channel  = require('../models/Channel.js')

router.route('/:searchid/:offerid')
  .get(auth.isAuthenticated, function(req, res, next) {
    let { searchid, offerid } = req.params
    let properties = { searchid, offerid }
    Channel.find(properties, function(err, channel) {
      if (err) {
        console.log(err)
        return next(err)
      }
      res.json(channel)
    })
  })

router.route('/')
  .post(auth.isAuthenticated, function(req, res, next) {
    Channel.create(req.body, function (err, channel) {
      if (err) {
        console.log(err)
        return next(err)
      }
      res.json(channel)
    })
  })

module.exports = router
