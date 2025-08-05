// Script to fix missing fields in Property documents
const mongoose = require('mongoose');
const Property = require('../models/Property');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/kodipay';

async function fixProperties() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  const properties = await Property.find({});
  let updated = 0;
  for (const property of properties) {
    let changed = false;
    if (!property.address) {
      property.address = 'Unknown Address'; // Use a non-empty default
      changed = true;
    }
    if (property.rentAmount == null) {
      property.rentAmount = 0;
      changed = true;
    }
    if (!property.createdAt) {
      property.createdAt = new Date();
      changed = true;
    }
    if (!property.updatedAt) {
      property.updatedAt = new Date();
      changed = true;
    }
    if (changed) {
      await property.save();
      updated++;
    }
  }
  console.log(`Updated ${updated} properties.`);
  mongoose.disconnect();
}

fixProperties().catch(err => {
  console.error(err);
  mongoose.disconnect();
}); 