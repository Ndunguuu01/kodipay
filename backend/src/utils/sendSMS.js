const twilio = require('twilio');

const sendSMS = async (options) => {
  // Create Twilio client
  const client = twilio(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN
  );

  // Send SMS
  await client.messages.create({
    body: options.message,
    to: options.phone,
    from: process.env.TWILIO_PHONE_NUMBER,
  });
};

module.exports = sendSMS; 