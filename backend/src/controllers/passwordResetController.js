const crypto = require('crypto');
const User = require('../models/User');
const sendEmail = require('../utils/sendEmail'); // Assume a utility for sending emails

// @desc    Request password reset
// @route   POST /api/auth/request-password-reset
// @access  Public
const requestPasswordReset = async (req, res) => {
  const { email, phone } = req.body;

  if (!email && !phone) {
    return res.status(400).json({ message: 'Please provide either email or phone number' });
  }

  try {
    let user;
    if (email) {
      user = await User.findOne({ email });
    } else {
      user = await User.findOne({ phone });
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(20).toString('hex');

    // Hash token and set to resetPasswordToken field
    const resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    // Set token and expiration on user
    user.resetPasswordToken = resetPasswordToken;
    user.resetPasswordExpire = Date.now() + 3600000; // 1 hour

    await user.save();

    // Send reset token via email or SMS (here email assumed)
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

    const message = `You requested a password reset. Please make a PUT request to: \n\n ${resetUrl}`;

    try {
      await sendEmail({
        to: user.email,
        subject: 'Password Reset Request',
        text: message,
      });

      res.json({ message: 'Password reset email sent' });
    } catch (err) {
      user.resetPasswordToken = undefined;
      user.resetPasswordExpire = undefined;
      await user.save();

      console.error('Email sending error:', err);
      res.status(500).json({ message: 'Email could not be sent' });
    }
  } catch (error) {
    console.error('Request password reset error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Reset password
// @route   PUT /api/auth/reset-password/:resetToken
// @access  Public
const resetPassword = async (req, res) => {
  const resetToken = req.params.resetToken;
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ message: 'Please provide a new password' });
  }

  // Hash token to compare with DB
  const resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');

  try {
    const user = await User.findOne({
      resetPasswordToken,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    // Set new password
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save();

    res.json({ message: 'Password reset successful' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  requestPasswordReset,
  resetPassword,
};
