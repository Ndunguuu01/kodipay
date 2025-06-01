const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Property = require('../models/Property');
const Bill = require('../models/Bill');
require('dotenv').config();

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

const seedUsers = async () => {
  try {
    // Create admin user
    const adminPassword = await bcrypt.hash('admin123', 10);
    const admin = await User.create({
      name: 'Admin User',
      email: 'admin@example.com',
      password: adminPassword,
      role: 'admin',
      isAdmin: true,
    });

    // Create property owner
    const ownerPassword = await bcrypt.hash('owner123', 10);
    const owner = await User.create({
      name: 'Property Owner',
      email: 'owner@example.com',
      password: ownerPassword,
      role: 'user',
    });

    // Create tenant
    const tenantPassword = await bcrypt.hash('tenant123', 10);
    const tenant = await User.create({
      name: 'John Tenant',
      email: 'tenant@example.com',
      password: tenantPassword,
      role: 'user',
    });

    return { admin, owner, tenant };
  } catch (error) {
    console.error('Error seeding users:', error);
    throw error;
  }
};

const seedProperties = async (owner) => {
  try {
    const property = await Property.create({
      name: 'Sunset Apartments',
      address: {
        street: '123 Main St',
        city: 'Nairobi',
        state: 'Nairobi',
        zipCode: '00100',
      },
      type: 'apartment',
      units: [
        {
          number: '101',
          type: '2bed',
          rent: 50000,
          status: 'occupied',
          tenant: owner._id,
        },
        {
          number: '102',
          type: '1bed',
          rent: 35000,
          status: 'available',
        },
      ],
      owner: owner._id,
      amenities: ['Parking', 'Security', 'Gym'],
      description: 'Modern apartment complex in the heart of the city',
      status: 'active',
    });

    return property;
  } catch (error) {
    console.error('Error seeding properties:', error);
    throw error;
  }
};

const seedBills = async (property, tenant) => {
  try {
    const bill = await Bill.create({
      property: property._id,
      unit: property.units[0]._id,
      tenant: tenant._id,
      type: 'rent',
      amount: 50000,
      dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      status: 'pending',
      description: 'Monthly rent payment',
      createdBy: property.owner,
    });

    return bill;
  } catch (error) {
    console.error('Error seeding bills:', error);
    throw error;
  }
};

const seedData = async () => {
  try {
    await connectDB();

    // Clear existing data
    await User.deleteMany({});
    await Property.deleteMany({});
    await Bill.deleteMany({});

    console.log('Cleared existing data');

    // Seed users
    const { admin, owner, tenant } = await seedUsers();
    console.log('Seeded users');

    // Seed properties
    const property = await seedProperties(owner);
    console.log('Seeded properties');

    // Seed bills
    const bill = await seedBills(property, tenant);
    console.log('Seeded bills');

    console.log('Database seeded successfully');
    process.exit();
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
};

seedData(); 