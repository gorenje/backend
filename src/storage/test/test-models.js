var chai = require('chai');
var should = chai.should();
var assert = chai.assert;

var Offer = require('../models/Offer')
var Search = require('../models/Search')
var geolib = require('geolib')

describe('Models', function() {
  it('should have a within_range method for Offer', function(done){
    var offer  = new Offer();
    var search = new Search();

    offer.location = {
      coordinates: [13.4502912, 52.5140393],
    }
    offer.radiusMeters = 100;

    search.location = {
      coordinates: [13.4503912, 52.5141393],
    }
    assert.isOk( offer.is_search_within_range(search) );

    search.location = {
      coordinates:  [13.4502912, 52.5140393],
    }
    assert.isOk( offer.is_search_within_range(search) );

    search.location = {
      coordinates: [13.4603912, 52.5141393],
    }
    assert.isOk( !offer.is_search_within_range(search) );

    search.location = {
      coordinates: [13.4503912, 52.5241393],
    }
    assert.isOk( !offer.is_search_within_range(search) );

    done();
  });

  it('should have a within_range method for Search', function(done){
    var offer  = new Offer();
    var search = new Search();

    search.location = {
      coordinates: [13.4502912, 52.5140393],
    }
    search.radiusMeters = 100;

    offer.location = {
      coordinates: [13.4503912, 52.5141393],
    }
    assert.isOk( search.is_offer_within_range(offer) );

    offer.location = {
      coordinates: [13.4502912, 52.5140393],
    }
    assert.isOk( search.is_offer_within_range(offer) );

    offer.location = {
      coordinates: [13.4603912, 52.5141393],
    }
    assert.isOk( !search.is_offer_within_range(offer) );

    offer.location = {
      coordinates: [13.4503912, 52.5241393],
    }
    assert.isOk( !search.is_offer_within_range(offer) );

    done();
  });

  it('should have a valid method for offer', function(done){
    var offer = new Offer();
    var timestamp = (new Date()).getTime();

    assert.isOk(!offer.is_valid());

    offer.validfrom = timestamp - 10000;
    offer.validuntil = timestamp + 10000;
    assert.isOk(offer.is_valid());

    offer.validfrom = timestamp + 10000;
    offer.validuntil = timestamp - 10000;
    assert.isOk(!offer.is_valid());

    offer.validfrom = timestamp + 11000;
    offer.validuntil = timestamp + 10000;
    assert.isOk(!offer.is_valid());

    done();
  });

  it('should have a valid method for offer', function(done){
    var search = new Search();
    var timestamp = (new Date()).getTime();

    assert.isOk(!search.is_valid());

    search.validfrom = timestamp - 10000;
    search.validuntil = timestamp + 10000;
    assert.isOk(search.is_valid());

    search.validfrom = timestamp + 10000;
    search.validuntil = timestamp - 10000;
    assert.isOk(!search.is_valid());

    search.validfrom = timestamp + 11000;
    search.validuntil = timestamp + 10000;
    assert.isOk(!search.is_valid());

    done();
  });

  it('should have a clone method for Offer', function(done){
    var offer = new Offer();

    offer.location = {
      coordinates: [100,50],
    }
    offer.place= {
      en: { 'Country': "Fubar"
      }
    }

    assert.deepEqual(offer.location.coordinates, [100,50]);
    assert.deepEqual(offer.place, {en: { "Country": "Fubar" } });

    var cln = offer.cloneReplacingLngLat(1,2);
    assert.deepEqual(cln.location.coordinates, [1,2]);
    assert.deepEqual(cln.place, {});

    done();
  });

  it('should have a clone method for Search', function(done){
    var search = new Search();

    search.location = {
      coordinates: [100,50],
    }
    search.place = {
      en: { 'Country': "Fubar"
      }
    }

    assert.deepEqual(search.location.coordinates, [100,50]);
    assert.deepEqual(search.place, {en: { "Country": "Fubar" } });

    var cln = search.cloneReplacingLngLat(1,2);
    assert.deepEqual(cln.location.coordinates, [1,2]);
    assert.deepEqual(cln.place, {});

    done();
  });

  it('should have tracking Parameters (Search)', function(done){
    var search = new Search();

    search.location = {
      coordinates: [100,50],
    }
    search.place = {
      en: { 'Country': "Fubar"
      }
    }
    search.text = "Fubar";

    var hsh = search.trackingParams();
    var tmp = JSON.parse(JSON.stringify(search));

    assert.strictEqual(hsh.lng, 100)
    assert.strictEqual(hsh.lat, 50)
    assert.strictEqual(hsh.title, "Fubar")
    assert.strictEqual(hsh._id, tmp._id)

    done();
  });
});
