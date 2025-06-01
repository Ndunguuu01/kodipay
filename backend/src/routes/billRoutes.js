const express = require('express');
const router = express.Router();
const {
  createBill,
  getBills,
  getBill,
  updateBill,
  deleteBill,
  addPayment,
  getBillStats,
} = require('../controllers/billController');
const { protect } = require('../middleware/auth');

// Protect all routes
router.use(protect);

// Bill routes
router.route('/')
  .post(createBill)
  .get(getBills);

router.route('/stats')
  .get(getBillStats);

router.route('/:id')
  .get(getBill)
  .put(updateBill)
  .delete(deleteBill);

// Payment routes
router.route('/:id/payments')
  .post(addPayment);

module.exports = router; 