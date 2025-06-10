require('dotenv').config();
const express = require('express');
const app = express();

const database = require('./config/database');
database.connectToDatabase();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});