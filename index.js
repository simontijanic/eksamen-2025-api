require('dotenv').config();
const express = require('express');
const app = express();

const cors = require("cors")
app.use(cors());

const voteLimiter = require('./utils/voteLimiter');

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