const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

async function migrateRoles() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Update all users with role 'owner' to 'landlord'
    const result = await User.updateMany(
      { role: 'owner' },
      { $set: { role: 'landlord' } }
    );

    console.log(`Updated ${result.modifiedCount} users from 'owner' to 'landlord' role`);

    // Verify the changes
    const users = await User.find({});
    console.log('\nCurrent users in database:');
    users.forEach(user => {
      console.log(`- ${user.name}: ${user.role}`);
    });

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

migrateRoles(); 