var chai = require('chai');
var should = chai.should();
var assert = chai.assert;
var mongoose = require('mongoose')

describe('Mongoose', function() {
  it('should valid OBjectIds', function(done){
    assert.isOk(mongoose.Types.ObjectId.isValid("zzzzzzzzzzzz"));
    assert.isOk(!mongoose.Types.ObjectId.isValid("undefined"));
    assert.isOk(mongoose.Types.ObjectId.isValid("5969186ad028210004ba61d3"));

    var ids = ["5969186ad028210004ba61d3", "undefined"]
    var new_ids = ids.filter( (value) => {
      return mongoose.Types.ObjectId.isValid(value);
    });
    assert.deepEqual( new_ids, ["5969186ad028210004ba61d3"])
    done();
  });
});
