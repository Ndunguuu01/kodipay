const sendSMS = require('../utils/sendSMS');

// @desc    Send SMS
// @route   POST /api/sms/send
// @access  Private
const sendSMSMessage = async (req, res) => {
  try {
    const { phone, message } = req.body;

    if (!phone || !message) {
      return res.status(400).json({ message: 'Please provide both phone number and message' });
    }

    await sendSMS({
      phone,
      message,
    });

    res.json({ message: 'SMS sent successfully' });
  } catch (error) {
    console.error('Send SMS error:', error);
    res.status(500).json({ message: 'Failed to send SMS' });
  }
};

module.exports = {
  sendSMSMessage,
}; 