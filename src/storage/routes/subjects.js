var express = require('express');
var router = express.Router();
var auth = require('./auth');

var mongoose = require('mongoose');

var Subject = require('../models/Subject.js');

function compareRank(a, b) {
  if (a.rank < b.rank) return 1;
  if (a.rank > b.rank) return -1;
  var akw = a.keywords.join(' ');
  var bkw = b.keywords.join(' ');
  if (akw < bkw) return -1;
  if (akw > bkw) return 1;
  return 0;
}

function stupidSort(subjects, keywords) {
  return subjects.map((subject) => {
    var ranked;
    ranked=JSON.parse(JSON.stringify(subject));
    ranked.rank=0
    ranked.isKeyword=[];
    subject.keywords.map((keyword) => {
      var index = keywords.indexOf(keyword);
      if (index >= 0) {
        ranked.rank++;
        ranked.isKeyword.push(true);
      } else {
        ranked.isKeyword.push(false);
      }
    });
    return ranked;
  })
  .sort(compareRank);
}
 
router.route('/')
  .get(auth.isAuthenticated, function(req, res, next) {
    var properties = {}
    var keywords   = req.query.keywords;
    var owner      = req.query.owner;
    if (keywords) {
      properties.keywords = { $in: keywords };
    } else {
      keywords = [];
    }
    if (owner) {
      properties.owner = owner;
    }
    Subject.find(properties, function(err, subjects) {
      if (err) return next(err);
      sortedSubjects=stupidSort(subjects, keywords);
      res.json(sortedSubjects);
    });
  })
  .post(auth.isAuthenticated, function(req, res, next) {
    Subject.create(req.body, function (err, post) {
      if (err) return next(err);
      res.json(post);
    });
  })
  .delete(auth.isAuthenticated, function(req, res, next) {
    Subject.remove({}, function (err, post) {
      if (err) return next(err);
      res.json(post);
    });
  });

router.route('/:id')
  .put(auth.isAuthenticated, function(req, res, next) {
    Subject.findByIdAndUpdate(req.params.id, req.body, function (err, post) {
      if (err) return next(err);
      res.json(post);
    });
  })
  .delete(auth.isAuthenticated, function(req, res, next) {
    Subject.findByIdAndRemove(req.params.id, function (err, post) {
      if (err) return next(err);
      res.json(post);
    });
  });

module.exports = router;
