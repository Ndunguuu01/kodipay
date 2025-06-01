const mongoose = require('mongoose');

const billSchema = mongoose.Schema(
  {
    property: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Property',
      required: true,
    },
    unit: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    tenant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['rent', 'utilities', 'maintenance', 'other'],
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    dueDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'overdue', 'cancelled'],
      default: 'pending',
    },
    description: String,
    attachments: [String],
    paymentHistory: [
      {
        amount: Number,
        date: Date,
        method: {
          type: String,
          enum: ['cash', 'bank_transfer', 'mobile_money', 'other'],
        },
        reference: String,
        notes: String,
      },
    ],
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Calculate total paid amount
billSchema.virtual('totalPaid').get(function () {
  return this.paymentHistory.reduce((total, payment) => total + payment.amount, 0);
});

// Calculate remaining amount
billSchema.virtual('remainingAmount').get(function () {
  return this.amount - this.totalPaid;
});

// Check if bill is fully paid
billSchema.virtual('isFullyPaid').get(function () {
  return this.remainingAmount <= 0;
});

// Update status based on payment and due date
billSchema.methods.updateStatus = function () {
  const now = new Date();
  
  if (this.isFullyPaid) {
    this.status = 'paid';
  } else if (now > this.dueDate) {
    this.status = 'overdue';
  } else {
    this.status = 'pending';
  }
};

module.exports = mongoose.model('Bill', billSchema); 