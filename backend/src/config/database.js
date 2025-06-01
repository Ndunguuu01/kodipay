const mongoose = require('mongoose');

const getMongoUri = () => {
  if (process.env.NODE_ENV === 'test') {
    if (!process.env.MONGODB_URI_TEST) {
      throw new Error('MONGODB_URI_TEST is not defined in environment variables');
    }
    return process.env.MONGODB_URI_TEST;
  }
  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is not defined in environment variables');
  }
  return process.env.MONGODB_URI;
};

const connectDB = async () => {
  try {
    const uri = getMongoUri();
    await mongoose.connect(uri);
    console.log(`MongoDB connected: ${uri}`);
    
    // Handle connection errors after initial connection
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected');
    });

    // Handle process termination
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('MongoDB connection closed through app termination');
      process.exit(0);
    });

  } catch (error) {
    console.error('MongoDB connection error:', error.message);
    process.exit(1);
  }
};

module.exports = connectDB; 