const express = require('express');
const router = express.Router();
const {
  createTenant,
  getTenants,
  getTenant,
  updateTenant,
  deleteTenant,
} = require('../controllers/tenantController');
const { protect } = require('../middleware/auth');

// Protect all routes
router.use(protect);

// Tenant routes
router.route('/')
  .post(createTenant)
  .get(getTenants);

router.route('/:id')
  .get(getTenant)
  .put(updateTenant)
  .delete(deleteTenant);

module.exports = router; 