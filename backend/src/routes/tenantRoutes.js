const express = require('express');
const router = express.Router();
const {
  createTenant,
  getTenants,
  getTenant,
  updateTenant,
  deleteTenant,
  deleteAllTenants,
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

router.route('/all')
  .delete(deleteAllTenants);

module.exports = router;
