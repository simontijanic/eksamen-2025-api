const mongoose = require('mongoose');

const voteSchema = new mongoose.Schema({
    imageId: { type: String, required: true, unique: true },
    votes: { type: Number, default: 0 }
});

module.exports = mongoose.model('Vote', voteSchema);
