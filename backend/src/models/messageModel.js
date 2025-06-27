const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  senderName: { type: String },
  senderPhoneNumber: { type: String },
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  recipientPhoneNumber: { type: String },
  content: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  isGroupMessage: { type: Boolean, default: false },
  propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property' },
  isRead: { type: Boolean, default: false },
});

module.exports = mongoose.model('Message', messageSchema); 