const express = require('express');
const router = express.Router();
const {
  getMessages,
  getGroupMessages,
  getDirectMessages,
  sendGroupMessage,
  sendDirectMessage,
} = require('../controllers/messageController');
const { protect } = require('../middleware/auth'); // Assuming auth middleware

router.route('/')
  .get(protect, getMessages);

router.route('/group/:propertyId')
  .get(protect, getGroupMessages);

router.route('/direct/:userId')
  .get(protect, getDirectMessages);

router.route('/group')
  .post(protect, sendGroupMessage);

router.route('/direct')
  .post(protect, sendDirectMessage);

module.exports = router;
