require('dotenv').config();
const express = require('express');
const app = express();

const cors = require("cors");
app.use(cors());

const database = require('./config/database');
database.connectToDatabase();

const jokeRoutes = require('./routes/jokeRoutes');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api', jokeRoutes);

app.listen(process.env.PORT, () => {
  console.log('Server is running on port 3000');
});