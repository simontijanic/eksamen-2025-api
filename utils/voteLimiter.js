const rateLimit = require('express-rate-limit');

// Rate limiting: maks 1 stemme per 3 sekunder per IP på /api/vote
const voteLimiter = rateLimit({
  windowMs: 3 * 1000, // 3 sekunder
  max: 1,
  message: { message: 'Vent litt før du stemmer igjen.' }
});

module.exports = voteLimiter;
