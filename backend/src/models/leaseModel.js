const mongoose = require('mongoose');

const leaseSchema = mongoose.Schema(
  {
    tenantId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
    },
    propertyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Property',
      required: true,
    },
    unitId: {
      type: mongoose.Schema.Types.ObjectId,
      required: false,
    },
    leaseStart: {
      type: Date,
      required: true,
    },
    leaseEnd: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'pending'],
      default: 'active',
    },
    notes: String,
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Lease', leaseSchema); 