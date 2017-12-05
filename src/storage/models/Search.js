var mongoose  = require('mongoose');
var geolib    = require('geolib');
var hlpr      = require('../lib/helpers');
var notifier  = require('../lib/notifier')
var qryHelper = require('../lib/query_helper')

var SearchSchema = new mongoose.Schema({
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
    radius: {
      type: Number,
      required: false,
    },
    dimension: {
      longitudeDelta: {
        type: Number,
        required: true,
      },
      latitudeDelta: {
        type: Number,
        required: true,
      },
    },
    place: {
      type : mongoose.Schema.Types.Mixed,
      default : {},
      required: false,
    },
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

SearchSchema.methods.cloneReplacingLngLat = function(lng, lat) {
  var tmp = JSON.parse(JSON.stringify(this));
  tmp.location.coordinates = [lng, lat]
  tmp.location.place = {}
  return tmp;
};

SearchSchema.methods.latitude = function() {
  return this.location.coordinates[1];
};

SearchSchema.methods.longitude = function() {
  return this.location.coordinates[0];
};

SearchSchema.methods.latitudeDelta = function() {
  return this.location.dimension.latitudeDelta;
};

SearchSchema.methods.longitudeDelta = function() {
  return this.location.dimension.longitudeDelta;
};

SearchSchema.methods.radius = function() {
  return this.location.radius;
};

SearchSchema.methods.is_valid = function() {
  return hlpr.is_valid(this);
};

SearchSchema.methods.is_offer_within_range = function(offer) {
  return this.is_point_within_range(offer.longitude(), offer.latitude());
};

SearchSchema.methods.is_point_within_range = function(lng, lat) {
  var pt = { latitude: lat, longitude: lng  }
  return geolib.isPointInside(pt, hlpr.generate_polygon(this));
};

SearchSchema.methods.findMatchingOffersAndNotify = function(next,callback) {
  var SELF  = this;
  var Offer = require('./Offer');

  Offer.find(qryHelper.lookupProps(SELF,{}))
    .cursor()
    .on('data', function(offer){
      if ( offer.is_search_within_range(SELF) ) {
        notifier.matchFound(offer, SELF);
      }
    })
    .on('end', function(){
      callback();
    });
}

SearchSchema.methods.trackingParams = function(action) {
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

module.exports = mongoose.model('Search', SearchSchema);
