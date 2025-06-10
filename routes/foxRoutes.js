const express = require('express');
const router = express.Router();
const foxController = require('../controllers/foxController');

router.get('/images', foxController.getRandomImages);
router.post('/vote', foxController.voteForFox);
router.get('/stats', foxController.getStats);

module.exports = router;
