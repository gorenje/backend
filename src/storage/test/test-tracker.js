var chai = require('chai');
var should = chai.should();
var assert = chai.assert;

var tracker = require('../lib/tracker')

var fakeweb = require('node-fakeweb');
var request = require('request');

describe('Tracker', function() {
  it("should send event", function(done){
    fakeweb.allowNetConnect = false;
    var spy = fakeweb.registerUri({
      uri: 'http://localhost:3000/w/fubar?fubar=fubar',
      body: '',
      contentType: "application/json"
    })

    tracker.sendTrackingEvent("fubar", {fubar: "fubar"}, function(d,resp){
      assert.strictEqual(spy.useCount, 1);
      done();
    });
  });
});
