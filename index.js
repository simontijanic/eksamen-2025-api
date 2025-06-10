require('dotenv').config();
const express = require('express');
const app = express();
const cors = require("cors")

const database = require('./config/database');
database.connectToDatabase();

const foxRoutes = require('./routes/foxRoutes');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(cors());

app.use('/api', foxRoutes);

app.listen(process.env.PORT, () => {
  console.log('Server is running on port 3000');
});