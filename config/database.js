const mongoose = require('mongoose');

exports.connectToDatabase = async () => {
  try {
    const dbUri = process.env.MONGODB_URI;
    await mongoose.connect(dbUri);
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  }
}