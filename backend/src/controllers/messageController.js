const Message = require('../models/messageModel'); // Assuming a Mongoose model for messages
const asyncHandler = require('express-async-handler');
const User = require('../models/User');

// @desc    Get all messages
// @route   GET /api/messages
// @access  Private
const getMessages = asyncHandler(async (req, res) => {
  const messages = await Message.find({}).sort({ createdAt: -1 });
  res.json(messages);
});

// @desc    Get group messages by propertyId
// @route   GET /api/messages/group/:propertyId
// @access  Private
const getGroupMessages = asyncHandler(async (req, res) => {
  const { propertyId } = req.params;
  if (!propertyId) {
    res.status(400);
    throw new Error('Property ID is required');
  }
  const messages = await Message.find({ propertyId }).sort({ createdAt: 1 });
  res.json(messages);
});

// @desc    Get direct messages between two users
// @route   GET /api/messages/direct/:userId
// @access  Private
const getDirectMessages = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  if (!userId) {
    res.status(400);
    throw new Error('User ID is required');
  }
  // Assuming userId is a combination of sender-recipient or similar
  const messages = await Message.find({
    $or: [
      { senderId: userId },
      { recipientId: userId }
    ]
  }).sort({ createdAt: 1 });
  res.json(messages);
});

// @desc    Send group message
// @route   POST /api/messages/group
// @access  Private
const sendGroupMessage = asyncHandler(async (req, res) => {
  console.log('sendGroupMessage called with body:', req.body);
  console.log('Content-Type:', req.get('Content-Type'));
  console.log('Headers:', req.headers);

  let { propertyId, senderId, content } = req.body;

  // Auto-fill senderId from authenticated user if not provided
  if (!senderId && req.user && req.user._id) {
    senderId = req.user._id.toString();
  }

  propertyId = typeof propertyId === 'string' ? propertyId.trim() : propertyId;
  senderId = typeof senderId === 'string' ? senderId.trim() : senderId;
  content = typeof content === 'string' ? content.trim() : content;

  console.log('Extracted values - propertyId:', propertyId, 'senderId:', senderId, 'content:', content);

  const missingFields = [];
  if (!propertyId) missingFields.push('propertyId');
  if (!senderId) missingFields.push('senderId');
  if (!content) missingFields.push('content');

  if (missingFields.length > 0) {
    console.log('Missing required fields:', missingFields);
    res.status(400);
    throw new Error(`Please provide ${missingFields.join(', ')}`);
  }

  // Fetch sender details
  const sender = await User.findById(senderId);
  if (!sender) {
    res.status(400);
    throw new Error('Sender not found');
  }
  const senderName = sender.name || sender.phone || 'Unknown User';
  const senderPhoneNumber = sender.phone || '';
  const message = new Message({
    propertyId,
    senderId,
    senderName,
    senderPhoneNumber,
    content,
    isGroupMessage: true,
  });
  const createdMessage = await message.save();
  res.status(201).json(createdMessage);
});

// @desc    Send direct message
// @route   POST /api/messages/direct
// @access  Private
const sendDirectMessage = asyncHandler(async (req, res) => {
  let { senderId, recipientId, content } = req.body;

  senderId = typeof senderId === 'string' ? senderId.trim() : senderId;
  recipientId = typeof recipientId === 'string' ? recipientId.trim() : recipientId;
  content = typeof content === 'string' ? content.trim() : content;

  const missingFields = [];
  if (!senderId) missingFields.push('senderId');
  if (!recipientId) missingFields.push('recipientId');
  if (!content) missingFields.push('content');

  if (missingFields.length > 0) {
    res.status(400);
    throw new Error(`Please provide ${missingFields.join(', ')}`);
  }

  // Fetch sender details
  const sender = await User.findById(senderId);
  if (!sender) {
    res.status(400);
    throw new Error('Sender not found');
  }
  const senderName = sender.name || sender.phone || 'Unknown User';
  const senderPhoneNumber = sender.phone || '';
  const message = new Message({
    senderId,
    recipientId,
    senderName,
    senderPhoneNumber,
    content,
    isGroupMessage: false,
  });
  const createdMessage = await message.save();
  res.status(201).json(createdMessage);
});

module.exports = {
  getMessages,
  getGroupMessages,
  getDirectMessages,
  sendGroupMessage,
  sendDirectMessage,
};
