const mongoose = require('mongoose');

const propertySchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a property name'],
    },
    address: {
      street: {
        type: String,
        required: [true, 'Please add a street address'],
      },
      city: {
        type: String,
        required: [true, 'Please add a city'],
      },
      state: {
        type: String,
        required: [true, 'Please add a state'],
      },
      zipCode: {
        type: String,
        required: [true, 'Please add a zip code'],
      },
    },
    type: {
      type: String,
      enum: ['apartment', 'house', 'commercial', 'other'],
      required: [true, 'Please specify property type'],
    },
    units: [
      {
        number: {
          type: String,
          required: [true, 'Please add a unit number'],
        },
        type: {
          type: String,
          enum: ['studio', '1bed', '2bed', '3bed', '4bed', 'other'],
          required: [true, 'Please specify unit type'],
        },
        rent: {
          type: Number,
          required: [true, 'Please specify rent amount'],
        },
        status: {
          type: String,
          enum: ['available', 'occupied', 'maintenance'],
          default: 'available',
        },
        tenant: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
      },
    ],
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    manager: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    amenities: [String],
    images: [String],
    description: String,
    status: {
      type: String,
      enum: ['active', 'inactive', 'maintenance'],
      default: 'active',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Property', propertySchema); 