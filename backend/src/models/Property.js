const mongoose = require('mongoose');

const propertySchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a property name'],
    },
    rentAmount: {
      type: Number,
      required: [true, 'Please specify rent amount'],
    },
    floors: [
      {
        floorNumber: {
          type: Number,
          required: [true, 'Please specify floor number'],
        },
        rooms: [
          {
            roomNumber: {
              type: String,
              required: [true, 'Please add a room number'],
            },
            tenantId: {
              type: mongoose.Schema.Types.ObjectId,
              ref: 'User',
              default: null,
            },
            isOccupied: {
              type: Boolean,
              default: false,
            },
          },
        ],
      },
    ],
    landlordId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Property', propertySchema); 