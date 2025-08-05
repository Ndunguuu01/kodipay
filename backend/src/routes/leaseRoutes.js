const express = require('express');
const router = express.Router();
const { getLeasesByTenant } = require('../controllers/leaseController');
const { protect } = require('../middleware/auth');

// Route to get leases for a tenant
router.get('/tenant/:tenantId', protect, getLeasesByTenant);

module.exports = router;
