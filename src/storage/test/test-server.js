var chai = require('chai');
var chaiHttp = require('chai-http');
var server = require('../app');
var should = chai.should();
var asst = chai.assert;

chai.use(chaiHttp);

describe('Basic Server', function() {
  it('should require authentication', function(done){
    if ( process.env.NO_MONGO_CONNECTION ) this.skip();
    chai.request(server.get_app())
    .get('/offers')
    .end(function(err,res){
      res.should.have.status(401);
      done();
    })
  });

  it('should get a list of offers', function(done){
    if ( process.env.NO_MONGO_CONNECTION ) this.skip();
    chai.request(server.get_app())
    .get('/offers?owner=_mocha_tests_')
    .auth('push', 'push')
    .end(function(err,res){
      res.should.have.status(200);
      asst.lengthOf(res.body, 0);
      done();
    })
  });
});
