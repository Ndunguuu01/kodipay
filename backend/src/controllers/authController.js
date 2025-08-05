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

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, getJwtSecret(), {
    expiresIn: '1d',
  });
};

// Generate refresh token
const generateRefreshToken = (id) => {
  return jwt.sign({ id }, getJwtSecret(), {
    expiresIn: '7d',
  });
};

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = async (req, res) => {
  try {
    console.log('Registration request received:', {
      body: { ...req.body, password: '[REDACTED]' },
      headers: req.headers
    });
    console.log('DEBUG: Full req.body:', req.body);

    // Accept phoneNumber as alias for phone
    let { name, phone, phoneNumber, password, role, nationalId } = req.body;
    phone = phone || phoneNumber;

    // Force role to 'landlord' if not provided or invalid
    const allowedRoles = ['user', 'admin', 'landlord', 'tenant'];
    if (!role || !allowedRoles.includes(role)) {
      console.log('DEBUG: Forcing role to landlord');
      role = 'landlord';
    }

    // Validate required fields (remove email, add nationalId)
    if (!name || !phone || !password || !nationalId) {
      return res.status(400).json({
        message: 'Missing required fields',
        required: ['name', 'phone', 'password', 'nationalId']
      });
    }

    // Validate password length
    if (password.length < 6) {
      return res.status(400).json({
        message: 'Password must be at least 6 characters'
      });
    }

    // Check if user exists by phone or nationalId
    const userExists = await User.findOne({
      $or: [{ phone }, { nationalId }]
    });

    if (userExists) {
      if (userExists.phone === phone) {
        return res.status(400).json({ message: 'Phone number already exists' });
      }
      if (userExists.nationalId === nationalId) {
        return res.status(400).json({ message: 'National ID already exists' });
      }
    }

    console.log('Creating new user with data:', {
      name,
      phone,
      role,
      nationalId,
      passwordLength: password.length
    });

    // Create user
    const userData = {
      name,
      phone,
      password,
      role,
      nationalId,
    };
    const user = await User.create(userData);

    console.log('User created successfully:', {
      id: user._id,
      name: user.name,
      phone: user.phone
    });

    if (user) {
      const response = {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        token: generateToken(user._id),
        refreshToken: generateRefreshToken(user._id),
      };
      console.log('Sending registration response:', {
        ...response,
        token: '[REDACTED]',
        refreshToken: '[REDACTED]'
      });
      res.status(201).json(response);
    }
  } catch (error) {
    console.error('Registration error:', error);
    
    // Handle specific error types
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      console.error('Validation errors:', validationErrors);
      return res.status(400).json({
        message: 'Validation error',
        errors: validationErrors
      });
    }
    
    if (error.code === 11000) {
      if (error.keyPattern.phone) {
        return res.status(400).json({ message: 'Phone number already exists' });
      }
      if (error.keyPattern.nationalId) {
        return res.status(400).json({ message: 'National ID already exists' });
      }
    }

    // Log the full error for debugging
    console.error('Full registration error:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });

    res.status(500).json({ 
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
  try {
    console.log('Login request received:', {
      body: { ...req.body, password: '[REDACTED]' },
      headers: req.headers
    });

    const { phone, password } = req.body;

    if (!phone) {
      return res.status(400).json({ message: 'Please provide phone number' });
    }

    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    // Find user by phone
    let user;
    user = await User.findOne({ phone }).select('+password');

    if (!user) {
      console.log('User not found');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    console.log('User found:', {
      id: user._id,
      name: user.name,
      phone: user.phone
    });

    // Check if password matches
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      console.log('Password does not match');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    console.log('Password matched, generating tokens');

    const response = {
      _id: user._id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      token: generateToken(user._id),
      refreshToken: generateRefreshToken(user._id),
    };

    // Save the generated refresh token to the user document
    await User.findByIdAndUpdate(user._id, { refreshToken: response.refreshToken });
    console.log(`Backend: Saved refresh token for user ${user._id} during login: ${response.refreshToken}`);

    console.log('Sending login response:', {
      ...response,
      token: '[REDACTED]',
      refreshToken: '[REDACTED]'
    });

    res.json(response);
  } catch (error) {
    console.error('Login error:', error);
    
    // Handle specific error types
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      console.error('Validation errors:', validationErrors);
      return res.status(400).json({
        message: 'Validation error',
        errors: validationErrors
      });
    }

    // Log the full error for debugging
    console.error('Full login error:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });

    res.status(500).json({ 
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Refresh token
// @route   POST /api/auth/refresh-token
// @access  Public
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      console.warn('Backend: Refresh token is required in refresh request.');
      return res.status(401).json({ message: 'Refresh token is required' });
    }

    console.log(`Backend: Received refresh token in refresh request: ${refreshToken}`);

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, getJwtSecret());
      console.log(`Backend: Refresh token decoded successfully for user ID: ${decoded.id}`);
    } catch (jwtError) {
      console.error(`Backend: JWT Verification failed for refresh token: ${jwtError.message}`);
      // If verification fails, it's an invalid token format or signature
      return res.status(401).json({ message: 'Invalid refresh token format' }); // More specific error
    }

    // Only proceed if decoded was successfully assigned
    if (!decoded) {
      console.error('Backend: Decoded token is undefined after verification attempt.');
      return res.status(401).json({ message: 'Invalid refresh token verification' }); // Should not happen with proper error handling above, but as a safeguard
    }

    // Get user from the token
    const user = await User.findById(decoded.id);

    if (!user) {
      console.warn(`Backend: User not found for decoded refresh token ID: ${decoded.id}`);
      return res.status(401).json({ message: 'User not found' });
    }

    console.log(`Backend: Retrieved user ${user._id} from DB. Stored refresh token: ${user.refreshToken}`);

    // Check if the provided refresh token matches the one stored in the user document
    console.log(`Backend: User found: ${user._id}, comparing received refresh token with stored one.`);
    console.log(`Backend: Stored refresh token for user ${user._id}: ${user.refreshToken}`);
    console.log(`Backend: Comparing received and stored tokens: ${refreshToken === user.refreshToken}`);
    if (user.refreshToken !== refreshToken) {
        // If it doesn't match, it's either an old/invalid refresh token or a suspicious activity
        // Invalidate all tokens for this user to be safe (optional but recommended for security)
        user.refreshToken = null; // Clear the refresh token
        await user.save();
        console.warn(`Backend: Invalid refresh token used for user ${user._id}. Tokens invalidated.`);
        return res.status(401).json({ message: 'Invalid refresh token' });
    }

    console.log(`Backend: Refresh token is valid for user ${user._id}. Generating new tokens.`);
    // Generate new tokens
    const newToken = generateToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    // Update the user document with the new refresh token
    console.log(`Backend: Saving new refresh token to user ${user._id}: ${newRefreshToken}`);
    user.refreshToken = newRefreshToken;
    await user.save();
    console.log(`User ${user._id} refresh token updated.`);

    res.json({
      token: newToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    console.error(error);
    res.status(401).json({ message: 'Invalid refresh token' });
  }
};

// @desc    Get current authenticated user
// @route   GET /api/auth/me
// @access  Private
const getCurrentUser = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Not authenticated' });
  }
  res.json({
    _id: req.user._id,
    name: req.user.name,
    phone: req.user.phone,
    role: req.user.role,
  });
};

module.exports = {
  registerUser,
  loginUser,
  refreshToken,
  getCurrentUser,
};
