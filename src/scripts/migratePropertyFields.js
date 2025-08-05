const mongoose = require('mongoose');
require('dotenv').config();

console.log('DEBUG: MONGO_URI =', process.env.MONGO_URI);

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err)); 