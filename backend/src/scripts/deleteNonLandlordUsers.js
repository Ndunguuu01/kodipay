const mongoose = require('mongoose');
const User = require('../models/User');
const dbConfig = require('../config/database');

async function deleteNonLandlordUsers() {
  try {
    await mongoose.connect(dbConfig.mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    const result = await User.deleteMany({ role: { $ne: 'landlord' } });
    console.log(`Deleted ${result.deletedCount} users with role not equal to 'landlord'`);

    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  } catch (error) {
    console.error('Error deleting non-landlord users:', error);
    process.exit(1);
  }
}

deleteNonLandlordUsers();
