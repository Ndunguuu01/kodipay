const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Fallback JWT secret for development - DO NOT USE IN PRODUCTION
const FALLBACK_JWT_SECRET = 'development-secret-key-change-in-production';

// Get JWT secret from environment or use fallback
const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    console.warn('WARNING: JWT_SECRET not found in environment variables. Using fallback secret. DO NOT USE IN PRODUCTION!');
    return FALLBACK_JWT_SECRET;
  }
  return secret;
};

const protect = async (req, res, next) => {
  console.log('Auth header:', req.headers.authorization); // Debug log
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];
      console.log('Extracted token:', token); // Debug log

      // Verify token
      const decoded = jwt.verify(token, getJwtSecret());
      console.log('Decoded token:', decoded); // Debug log

      // Get user from the token
      req.user = await User.findById(decoded.id).select('-password');
      console.log('Authenticated user:', req.user); // Debug log

      next();
      return; // Exit after successful authentication
    } catch (error) {
      console.error('Token verification error:', error); // Debug log
      res.status(401).json({ message: 'Not authorized, token failed' });
      return; // Exit on error
    }
  }

  // If we get here, no token was provided
  console.log('No token found in Authorization header for', req.method, req.originalUrl); // Debug log
  res.status(401).json({ message: 'Not authorized, no token' });
};

const admin = (req, res, next) => {
  if (req.user && req.user.isAdmin) {
    next();
  } else {
    res.status(401).json({ message: 'Not authorized as an admin' });
  }
};

module.exports = { protect, admin };
