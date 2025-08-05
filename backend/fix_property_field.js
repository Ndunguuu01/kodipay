const mongoose = require('mongoose');

// Connect to MongoDB with default connection
mongoose.connect('mongodb://127.0.0.1:27017/kodipay')
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

const fixPropertyFields = async () => {
  try {
    // Wait for connection to be ready
    await mongoose.connection.asPromise();
    
    const db = mongoose.connection.db;
    const propertiesCollection = db.collection('properties');
    
    console.log('Starting property field migration...');
    
    // Find all properties with 'landlord' field
    const propertiesWithLandlord = await propertiesCollection.find({ landlord: { $exists: true } }).toArray();
    console.log(`Found ${propertiesWithLandlord.length} properties with 'landlord' field`);
    
    if (propertiesWithLandlord.length === 0) {
      console.log('No properties found with "landlord" field. Migration not needed.');
      return;
    }
    
    // Update each property to rename 'landlord' to 'landlordId'
    for (const property of propertiesWithLandlord) {
      console.log(`Migrating property: ${property.name} (ID: ${property._id})`);
      
      await propertiesCollection.updateOne(
        { _id: property._id },
        { 
          $rename: { landlord: 'landlordId' }
        }
      );
      
      console.log(`Successfully migrated property: ${property.name}`);
    }
    
    console.log('Property field migration completed successfully!');
    
    // Verify the migration
    const propertiesWithLandlordId = await propertiesCollection.find({ landlordId: { $exists: true } }).toArray();
    const remainingPropertiesWithLandlord = await propertiesCollection.find({ landlord: { $exists: true } }).toArray();
    
    console.log(`Properties with 'landlordId' field: ${propertiesWithLandlordId.length}`);
    console.log(`Properties with 'landlord' field: ${remainingPropertiesWithLandlord.length}`);
    
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

// Run the migration
fixPropertyFields(); 