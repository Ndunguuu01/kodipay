const express = require('express');
const router = express.Router();


const authRoutes = require('./authRoutes');
const propertyRoutes = require('./propertyRoutes');
const billRoutes = require('./billRoutes');
const tenantRoutes = require('./tenantRoutes');
const paymentRoutes = require('./paymentRoutes');
const complaintRoutes = require('./complaintRoutes');
const messageRoutes = require('./messageRoutes');
const userRoutes = require('./userRoutes');  // Added userRoutes import
const leaseRoutes = require('./leaseRoutes'); // Added leaseRoutes import

// Health check route
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date(),
    uptime: process.uptime(),
  });
});

  
// API routes
router.use('/auth', authRoutes);
router.use('/properties', propertyRoutes);
router.use('/bills', billRoutes);
router.use('/tenants', tenantRoutes);
router.use('/payments', paymentRoutes);
router.use('/complaints', complaintRoutes);
router.use('/messages', messageRoutes);
router.use('/users', userRoutes);  // Added userRoutes registration
router.use('/leases', leaseRoutes); // Added leaseRoutes registration

module.exports = router;
