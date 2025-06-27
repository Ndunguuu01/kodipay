const express = require('express');
const router = express.Router();
const { sendSMSMessage } = require('../controllers/smsController');
const { protect } = require('../middleware/auth');

// Protect all routes
router.use(protect);

// SMS routes
router.post('/send', sendSMSMessage);

module.exports = router; 