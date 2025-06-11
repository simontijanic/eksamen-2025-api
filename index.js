require('dotenv').config();
const express = require('express');
const app = express();

const cors = require("cors")
app.use(cors());

const rateLimit = require('express-rate-limit');

// Rate limiting: maks 1 stemme per 3 sekunder per IP på /api/vote
const voteLimiter = rateLimit({
  windowMs: 3 * 1000, // 3 sekunder
  max: 1,
  message: { message: 'Vent litt før du stemmer igjen.' }
});

const database = require('./config/database');
database.connectToDatabase();

const foxRoutes = require('./routes/foxRoutes');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/vote', voteLimiter);

app.use('/api', foxRoutes);

app.listen(process.env.PORT, () => {
  console.log('Server is running on port 3000');
});