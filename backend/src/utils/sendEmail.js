const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
  // Create transporter
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  // Email options
  const mailOptions = {
    from: `"KodiPay Support" <${process.env.SMTP_FROM}>`,
    to: options.to,
    subject: options.subject,
    text: options.text,
  };

  // Send email
  await transporter.sendMail(mailOptions);
};

module.exports = sendEmail;
