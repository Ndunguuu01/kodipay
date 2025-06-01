const express = require('express');
const router = express.Router();
const {
  createPayment,
  getPayments,
  getPayment,
  updatePaymentStatus,
  getPaymentStats,
} = require('../controllers/paymentController');
const { protect } = require('../middleware/authMiddleware');

// Protect all routes
router.use(protect);

// Payment routes
router.route('/')
  .post(createPayment)
  .get(getPayments);

router.route('/stats')
  .get(getPaymentStats);

router.route('/:id')
  .get(getPayment);

router.route('/:id/status')
  .put(updatePaymentStatus);

module.exports = router; 