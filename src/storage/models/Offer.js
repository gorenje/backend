var mongoose  = require('mongoose');
var geolib    = require('geolib');
var hlpr      = require('../lib/helpers');
var notifier  = require('../lib/notifier')
var qryHelper = require('../lib/query_helper')

var OfferSchema = new mongoose.Schema({
  text: {
    type: String,
  },
  keywords: {
    type: [String],
    required: true,
  },
  owner: {
    type: String,
    required: true,
  },
  location: {
    'type': {
      type: String,
      required: true,
      default: "Point",
    },
    coordinates: {
      type: [Number],
      required: true,
    },
  },
  radiusMeters: {
    type: Number,
    required: false,
  },
  place: {
    type : mongoose.Schema.Types.Mixed,
    default : {},
    required: false,
  },
  showLocation: {
    type: Boolean,
    required: true,
    default: false,
  },
  allowContacts: {
    type: Boolean,
    required: true,
    default: false,
  },
  isMobile: {
    type: Boolean,
    required: true,
    default: false,
  },
  isActive: {
    type: Boolean,
    required: true,
    default: true,
  },
  created: {
    type: Number,
    required: true,
    default: (new Date()).getTime(),
  },
  modified: {
    type: Number,
    required: true,
    default: (new Date()).getTime(),
  },
  validfrom: {
    type: Number,
    required: false,
  },
  validuntil: {
    type: Number,
    required: false,
  },
  trusted: {
    type: Boolean,
    default: true,
  },
  images: {
    type: [String],
    required: false,
  },
  extdata: {
    type : mongoose.Schema.Types.Mixed,
    default : {},
    required: false,
  },
});

OfferSchema.methods.cloneReplacingLngLat = function(lng, lat) {
  var tmp = JSON.parse(JSON.stringify(this));
  tmp.location.coordinates = [lng, lat]
  tmp.location.place = {}
  return tmp;
};

OfferSchema.methods.latitude = function() {
  return this.location.coordinates[1];
};

OfferSchema.methods.longitude = function() {
  return this.location.coordinates[0];
};

OfferSchema.methods.radius = function() {
  return this.radiusMeters;
};

OfferSchema.methods.is_valid = function() {
  return hlpr.is_valid(this);
};

OfferSchema.methods.is_search_within_range = function(search) {
  return this.is_point_within_range(search.longitude(), search.latitude());
};

OfferSchema.methods.is_point_within_range = function(lng, lat) {
  var pt = { latitude: lat, longitude: lng  }
  return geolib.isPointInCircle(pt, { latitude: this.latitude(),
                                      longitude: this.longitude() },
                                this.radius())
};

OfferSchema.methods.findMatchingSearchesAndNotify = function(next,callback) {
  var SELF   = this;
  var Search = require('./Search');

  Search.find(qryHelper.lookupProps(SELF, {}))
    .cursor()
    .on('data', function(search) {
      if ( search.is_offer_within_range(SELF) ) {
        notifier.matchFound(SELF, search);
      }
    })
    .on('end', function() {
      callback();
    });
}

OfferSchema.methods.trackingParams = function(action) {
  var tmp = JSON.parse(JSON.stringify(this));

  return {
    action: action,
    _id:    tmp._id,
    isact:  this.isActive,
    title:  this.text,
    lat:    this.latitude(),
    lng:    this.longitude(),
    latD:   this.latitudeDelta(),
    lngD:   this.longitudeDelta(),
    radi:   this.radius()
  };
}

module.exports = mongoose.model('Offer', OfferSchema);
