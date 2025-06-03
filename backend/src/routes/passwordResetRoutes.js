const express = require('express');
const router = express.Router();
const {
  requestPasswordReset,
  resetPassword,
} = require('../controllers/passwordResetController');

router.post('/request-password-reset', requestPasswordReset);
router.put('/reset-password/:resetToken', resetPassword);

module.exports = router;
