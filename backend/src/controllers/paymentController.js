const Payment = require('../models/Payment');
const Bill = require('../models/Bill');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');

// M-Pesa Daraja credentials (replace with your own)
const MPESA_CONSUMER_KEY = 'A71GnliNfG2W5DmUxgk3JpulMtGd1lAHN1AyqxHqAT2BL7U5';
const MPESA_CONSUMER_SECRET = 'aX8dTxFmnekh7gYqTHPTqGcpApAsEM8jipF390R6hd7sgNHtrgBQLDpD3ACxEtzj';
const MPESA_SHORTCODE = '174379'; // Sandbox shortcode
const MPESA_PASSKEY = 'bfb279f9aa9bdbcf158e97dd71a467cd2c2c8a15bdc60c5d5b1b3b7c7e3c3bdf'; // Default sandbox passkey
const MPESA_BASE_URL = 'https://sandbox.safaricom.co.ke'; // Use live URL for production
const MPESA_CALLBACK_URL = 'https://your-backend.com/api/payments/mpesa/callback'; // Update to your public callback URL

// Helper: Get M-Pesa access token
async function getMpesaAccessToken() {
  const auth = Buffer.from(`${MPESA_CONSUMER_KEY}:${MPESA_CONSUMER_SECRET}`).toString('base64');
  const response = await axios.get(`${MPESA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials`, {
    headers: { Authorization: `Basic ${auth}` },
  });
  return response.data.access_token;
}

// Helper: Get timestamp
function getTimestamp() {
  const date = new Date();
  return date.getFullYear().toString() +
    String(date.getMonth() + 1).padStart(2, '0') +
    String(date.getDate()).padStart(2, '0') +
    String(date.getHours()).padStart(2, '0') +
    String(date.getMinutes()).padStart(2, '0') +
    String(date.getSeconds()).padStart(2, '0');
}

// @desc    Create new payment
// @route   POST /api/payments
// @access  Private
const createPayment = async (req, res) => {
  try {
    const { bill: billId, amount, method, notes } = req.body;

    // Verify bill exists
    const bill = await Bill.findById(billId);
    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Check if user has access
    if (
      bill.tenant.toString() !== req.user._id.toString() &&
      bill.createdBy.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    // Create payment
    const payment = await Payment.create({
      bill: billId,
      amount,
      method,
      notes,
      reference: `PAY-${uuidv4()}`,
      createdBy: req.user._id,
    });

    // Update bill status
    bill.paymentHistory.push({
      amount,
      date: new Date(),
      method,
      reference: payment.reference,
      notes,
    });
    bill.updateStatus();
    await bill.save();

    res.status(201).json(payment);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get all payments
// @route   GET /api/payments
// @access  Private
const getPayments = async (req, res) => {
  try {
    const payments = await Payment.find({
      $or: [
        { 'bill.tenant': req.user._id },
        { 'bill.createdBy': req.user._id },
      ],
    })
      .populate('bill', 'property unit tenant')
      .populate('createdBy', 'name email');

    res.json(payments);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single payment
// @route   GET /api/payments/:id
// @access  Private
const getPayment = async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id)
      .populate('bill', 'property unit tenant')
      .populate('createdBy', 'name email');

    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Check if user has access
    const bill = await Bill.findById(payment.bill);
    if (
      bill.tenant.toString() !== req.user._id.toString() &&
      bill.createdBy.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    res.json(payment);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update payment status
// @route   PUT /api/payments/:id/status
// @access  Private
const updatePaymentStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const payment = await Payment.findById(req.params.id);

    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Check if user has access
    const bill = await Bill.findById(payment.bill);
    if (bill.createdBy.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    payment.status = status;
    await payment.save();

    // Update bill status if payment is completed
    if (status === 'completed') {
      bill.updateStatus();
      await bill.save();
    }

    res.json(payment);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get payment statistics
// @route   GET /api/payments/stats
// @access  Private
const getPaymentStats = async (req, res) => {
  try {
    const stats = await Payment.aggregate([
      {
        $match: {
          $or: [
            { 'bill.tenant': req.user._id },
            { 'bill.createdBy': req.user._id },
          ],
        },
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
        },
      },
    ]);

    // Transform the array into the expected object format
    const result = {
      total: 0,
      pending: 0,
      completed: 0,
    };

    stats.forEach(stat => {
      if (stat._id === 'pending') {
        result.pending = stat.totalAmount;
      } else if (stat._id === 'completed') {
        result.completed = stat.totalAmount;
      }
      result.total += stat.totalAmount;
    });

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Initiate M-Pesa STK Push
// @route   POST /api/payments/mpesa/stkpush
// @access  Public or Private (as needed)
const mpesaStkPush = async (req, res) => {
  try {
    const { phone, amount, accountReference, description } = req.body;
    if (!phone || !amount) {
      return res.status(400).json({ message: 'Phone and amount are required' });
    }
    const accessToken = await getMpesaAccessToken();
    const timestamp = getTimestamp();
    const password = Buffer.from(`${MPESA_SHORTCODE}${MPESA_PASSKEY}${timestamp}`).toString('base64');

    const payload = {
      BusinessShortCode: MPESA_SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,
      PartyB: MPESA_SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: MPESA_CALLBACK_URL,
      AccountReference: accountReference || 'KodiPay',
      TransactionDesc: description || 'Payment',
    };

    const response = await axios.post(
      `${MPESA_BASE_URL}/mpesa/stkpush/v1/processrequest`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.status(200).json(response.data);
  } catch (error) {
    console.error('M-Pesa STK Push error:', error.response?.data || error.message);
    res.status(500).json({ message: 'M-Pesa STK Push failed', error: error.response?.data || error.message });
  }
};

// @desc    M-Pesa Payment Callback
// @route   POST /api/payments/mpesa/callback
// @access  Public
const mpesaCallback = async (req, res) => {
  // Safaricom will POST payment result here
  console.log('M-Pesa Callback:', JSON.stringify(req.body, null, 2));
  // TODO: Update payment status in your DB as needed
  res.status(200).json({ message: 'Callback received' });
};

module.exports = {
  createPayment,
  getPayments,
  getPayment,
  updatePaymentStatus,
  getPaymentStats,
  mpesaStkPush,
  mpesaCallback,
}; 