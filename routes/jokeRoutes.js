const express = require('express');
const router = express.Router();
const jokeController = require('../controllers/jokeController');

// Get a random joke
router.get('/joke', jokeController.getRandomJoke);
// Submit a review for a joke
router.post('/joke/review', jokeController.reviewJoke);
// Get average rating for a joke
router.get('/joke/average/:jokeId', jokeController.getJokeAverage);

module.exports = router;
