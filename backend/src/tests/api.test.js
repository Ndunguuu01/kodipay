const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');
const User = require('../models/User');
const Property = require('../models/Property');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');

let ownerToken;
let tenantToken;
let testProperty;
let testBill;
let testPayment;
let testTenantUser;

// Test data
const testOwner = {
  name: 'Test Owner',
  phone: '+254700000004',
  password: 'password123',
  role: 'landlord',
  nationalId: '12345681',
};

const testTenant = {
  name: 'Test Tenant',
  phone: '+254700000005',
  password: 'password123',
  role: 'tenant',
  nationalId: '12345682',
};

const testPropertyData = {
  name: 'Test Property',
  type: 'apartment',
  address: {
    street: '123 Test St',
    city: 'Test City',
    state: 'Test State',
    zipCode: '12345',
  },
  units: [
    {
      number: '101',
      type: '1bed',
      rent: 1000,
      status: 'available',
    },
  ],
  amenities: ['Parking', 'Security'],
  description: 'Test property description',
};

// Setup and teardown
beforeAll(async () => {
  // Clear all collections before tests
  const collections = Object.keys(mongoose.connection.collections);
  for (const collectionName of collections) {
    await mongoose.connection.collections[collectionName].deleteMany({});
  }
});

afterAll(async () => {
  await mongoose.connection.close();
});

// Auth tests
describe('Auth Endpoints', () => {
  it('should register a new owner', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send(testOwner);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('token');
    ownerToken = res.body.token;
  });

  it('should register a new tenant', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send(testTenant);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('token');
    tenantToken = res.body.token;
    testTenantUser = res.body;
  });

  it('should login existing user', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        phone: testOwner.phone,
        password: testOwner.password,
      });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
  });
});

// Property tests
describe('Property Endpoints', () => {
  it('should create a new property', async () => {
    const res = await request(app)
      .post('/api/properties')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send(testPropertyData);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('_id');
    testProperty = res.body;
  });

  it('should get all properties', async () => {
    const res = await request(app)
      .get('/api/properties')
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });
});

// Bill tests
describe('Bill Endpoints', () => {
  it('should create a new bill', async () => {
    const res = await request(app)
      .post('/api/bills')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        property: testProperty._id,
        unit: testProperty.units[0]._id,
        tenant: testTenantUser._id,
        type: 'rent',
        amount: 1000,
        dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        description: 'Monthly rent',
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('_id');
    testBill = res.body;
  });

  it('should get all bills', async () => {
    const res = await request(app)
      .get('/api/bills')
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });
});

// Payment tests
describe('Payment Endpoints', () => {
  it('should create a new payment', async () => {
    const res = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${tenantToken}`)
      .send({
        bill: testBill._id,
        amount: 1000,
        method: 'bank_transfer',
        notes: 'Test payment',
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('_id');
    testPayment = res.body;
  });

  it('should get all payments', async () => {
    const res = await request(app)
      .get('/api/payments')
      .set('Authorization', `Bearer ${tenantToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  it('should update payment status', async () => {
    const res = await request(app)
      .put(`/api/payments/${testPayment._id}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        status: 'completed',
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('completed');
  });

  it('should get payment statistics', async () => {
    const res = await request(app)
      .get('/api/payments/stats')
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('total');
    expect(res.body).toHaveProperty('pending');
    expect(res.body).toHaveProperty('completed');
  });
}); 