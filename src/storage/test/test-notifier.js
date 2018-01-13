var chai = require('chai');
var should = chai.should();
var assert = chai.assert;

var Offer = require('../models/Offer')
var Search = require('../models/Search')
var notifier = require('../lib/notifier')

var Client = require('node-rest-client').Client;
var fakeweb = require('node-fakeweb');
var request = require('request');

describe('Notifier', function() {
  it("should do nothing if offer or search invalid", function(done){
    var offr = new Offer();
    var srch = new Search();
    assert.isOk(!srch.is_valid());
    assert.isOk(!offr.is_valid());

    fakeweb.allowNetConnect = false;
    var spy = fakeweb.registerUri({uri: 'http://localhost:3000/notify',
                                   body: '{"status": "ok"}',
                                   contentType: "application/json"
    })
    notifier.matchFound(offr, srch)

    assert.strictEqual(spy.useCount, 0);
    done();
  });

  it("should send lat & lng", function(done){
    var offr = new Offer();
    var srch = new Search();
    var timestamp = (new Date()).getTime();

    srch.validfrom = timestamp - 10000;
    srch.validuntil = timestamp + 10000;
    assert.isOk(srch.is_valid());

    offr.validfrom = timestamp - 10000;
    offr.validuntil = timestamp + 10000;
    assert.isOk(offr.is_valid());

    offr.owner    = "Fubar"
    offr.text     = "text"
    offr.location = {
      coordinates: [100,50],
    }
    offr.radiusMeters = 123

    srch.owner    = "SNafo"
    srch.text     = "somemoregetx"
    srch.location = {
      coordinates: [101,51],
    }
    srch.radiusMeters = 100

    fakeweb.allowNetConnect = false;
    var spy = fakeweb.registerUri({uri: 'http://localhost:3000/notify',
                                   body: '{"status": "ok"}',
                                   contentType: "application/json"
    })

    assert.isOk(srch.is_valid());
    assert.isOk(offr.is_valid());
    notifier.matchFound(offr, srch)

    assert.strictEqual(spy.useCount, 1);

    var body = JSON.parse(spy.body)

    assert.strictEqual(body.category, "match_found")

    assert.strictEqual(body.offer.title, "text")
    assert.strictEqual(body.offer.device_id, "Fubar")
    assert.strictEqual(body.offer.lat, 50)
    assert.strictEqual(body.offer.lng, 100)
    assert.strictEqual(body.offer.radi, 123)

    assert.strictEqual(body.search.title, "somemoregetx")
    assert.strictEqual(body.search.device_id, "SNafo")
    assert.strictEqual(body.search.lat, 51)
    assert.strictEqual(body.search.lng, 101)
    assert.strictEqual(body.search.radi, 100)

    done();
  });
});
