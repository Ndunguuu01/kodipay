const Payment = require('../models/Payment');
const Bill = require('../models/Bill');
const { v4: uuidv4 } = require('uuid');

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

module.exports = {
  createPayment,
  getPayments,
  getPayment,
  updatePaymentStatus,
  getPaymentStats,
}; 