require('dotenv').config();

const mongoose = require('mongoose');

const getMongoUri = () => {
  if (process.env.NODE_ENV === 'test') {
    return process.env.MONGODB_URI_TEST || 'mongodb://127.0.0.1:27017/kodipay_test';
  }
  return process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kodipay';
};

const connectWithRetry = async (uri, options, maxRetries = 5) => {
  let retries = 0;
  
  while (retries < maxRetries) {
    try {
      console.log(`Attempting to connect to MongoDB (attempt ${retries + 1}/${maxRetries})...`);
      await mongoose.connect(uri, options);
      console.log(`MongoDB connected successfully to: ${uri}`);
      return;
    } catch (error) {
      retries++;
      console.error(`MongoDB connection attempt ${retries} failed:`, error.message);
      
      if (retries === maxRetries) {
        throw error;
      }
      
      // Wait for 5 seconds before retrying
      console.log('Waiting 5 seconds before retrying...');
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

const connectDB = async () => {
  try {
    const uri = getMongoUri();
    
    const options = {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    };

    await connectWithRetry(uri, options);
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected');
      // Attempt to reconnect
      connectWithRetry(uri, options);
    });

    mongoose.connection.on('reconnected', () => {
      console.log('MongoDB reconnected');
    });

  } catch (error) {
    console.error('MongoDB connection error:', error);
    console.error('\nPlease make sure MongoDB is installed and running on your system.');
    console.error('1. Download MongoDB from: https://www.mongodb.com/try/download/community');
    console.error('2. Run the installer and choose "Complete" installation');
    console.error('3. Make sure to check "Install MongoDB as a Service" during installation');
    console.error('4. After installation, open Windows Services (services.msc)');
    console.error('5. Find "MongoDB" in the list and make sure it\'s running');
    process.exit(1);
  }
};

module.exports = connectDB;
