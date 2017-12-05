var chai = require('chai');
var qryHelper = require("../lib/query_helper.js");
var should = chai.should();
var assert = chai.assert;

var Offer = require('../models/Offer')
var Search = require('../models/Search')

describe('Query Helper', function() {
  it('should generate properties for offer', function(done){
    var offer = new Offer();
    offer.owner = "Fubar"
    offer.location = {
      coordinates: [100,50],
      dimension: {
        longitudeDelta: 10,
        latitudeDelta: 5
      },
    }
    offer.keywords = ["one", "two", "three"]

    var props = qryHelper.lookupProps(offer, {});

    assert.strictEqual(offer.longitudeDelta(), 10);
    assert.strictEqual(offer.latitudeDelta(), 5);

    assert.isOk(props.validuntil);
    assert.isAbove((new Date()).getTime()+1, props.validuntil.$gt);

    assert.isOk(props.validfrom);
    assert.isAbove((new Date()).getTime()+1, props.validfrom.$lt);

    assert.strictEqual(props.keywords.$in, offer.keywords);
    assert.strictEqual(props.owner.$ne, offer.owner);

    assert.strictEqual(props.location.$geoWithin.$box[0][0], 95);
    assert.strictEqual(props.location.$geoWithin.$box[0][1], 47.5);
    assert.strictEqual(props.location.$geoWithin.$box[1][0], 105);
    assert.strictEqual(props.location.$geoWithin.$box[1][1], 52.5);

    done();
  });

  it('should generate properties for search', function(done){
    var search = new Search();
    search.owner = "Fubar"
    search.location = {
      coordinates: [100,50],
      dimension: {
        longitudeDelta: 10,
        latitudeDelta: 5
      },
    }
    search.keywords = ["one", "two", "three"]

    var props = qryHelper.lookupProps(search, {});

    assert.strictEqual(search.longitudeDelta(), 10);
    assert.strictEqual(search.latitudeDelta(), 5);

    assert.isOk(props.validuntil);
    assert.isAbove((new Date()).getTime()+1, props.validuntil.$gt);

    assert.isOk(props.validfrom);
    assert.isAbove((new Date()).getTime()+1, props.validfrom.$lt);

    assert.strictEqual(props.keywords.$in, search.keywords);
    assert.strictEqual(props.owner.$ne, search.owner);

    assert.strictEqual(props.location.$geoWithin.$box[0][0], 95);
    assert.strictEqual(props.location.$geoWithin.$box[0][1], 47.5);
    assert.strictEqual(props.location.$geoWithin.$box[1][0], 105);
    assert.strictEqual(props.location.$geoWithin.$box[1][1], 52.5);

    done();
  });

  it('should set location', function(done){
    var props = qryHelper.locationByGeoBox({}, 100, 50, 10, 5);

    assert.strictEqual(props.location.$geoWithin.$box[0][0], 95);
    assert.strictEqual(props.location.$geoWithin.$box[0][1], 47.5);
    assert.strictEqual(props.location.$geoWithin.$box[1][0], 105);
    assert.strictEqual(props.location.$geoWithin.$box[1][1], 52.5);

    done();
  });

  it('should set validatenessity', function(done){
    var props = qryHelper.validate({});

    assert.isOk(props.validuntil);
    assert.isAbove((new Date()).getTime()+1, props.validuntil.$gt);

    assert.isOk(props.validfrom);
    assert.isAbove((new Date()).getTime()+1, props.validfrom.$lt);
    done();
  });

  it('should set keywords', function(done){
    var tstObj = {
      owner: "fubar",
      keywords: ["one", "two"]
    }
    var props = qryHelper.keyWordsAndOwner(tstObj, {});

    assert.strictEqual(props.keywords.$in, tstObj.keywords);
    assert.strictEqual(props.owner.$ne, tstObj.owner);
    done();
  });
});
