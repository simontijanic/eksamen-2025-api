const mongoose = require('mongoose');

const jokeReviewSchema = new mongoose.Schema({
    jokeId: { type: Number, required: true },
    stars: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('JokeReview', jokeReviewSchema);
