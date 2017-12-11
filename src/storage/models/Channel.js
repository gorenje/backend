var mongoose = require('mongoose');

var ChannelSchema = new mongoose.Schema({
  searchid: {
    type: String,
    required: true,
  },
  offerid: {
    type: String,
    required: true,
  },
  created: {
    type: Number,
    required: true,
    default: (new Date()).getTime(),
  },
  url: {
    type: String,
    required: true,
  }
})

module.exports = mongoose.model('Channel', ChannelSchema);
