const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'default_jwt_secret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  });
};

// Generate refresh token
const generateRefreshToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_REFRESH_SECRET || 'default_refresh_secret', {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
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

    // Accept phoneNumber as alias for phone
    let { name, email, phone, phoneNumber, password, role = 'user' } = req.body;
    phone = phone || phoneNumber;

    // Validate required fields including email
    if (!name || !email || !phone || !password) {
      return res.status(400).json({
        message: 'Missing required fields',
        required: ['name', 'email', 'phone', 'password']
      });
    }

    // Validate password length
    if (password.length < 6) {
      return res.status(400).json({
        message: 'Password must be at least 6 characters'
      });
    }

    // Check if user exists by email or phone
    const userExists = await User.findOne({
      $or: [{ email }, { phone }]
    });

    if (userExists) {
      if (userExists.email === email) {
        return res.status(400).json({ message: 'Email already exists' });
      }
      if (userExists.phone === phone) {
        return res.status(400).json({ message: 'Phone number already exists' });
      }
    }

    console.log('Creating new user with data:', {
      name,
      email,
      phone,
      role,
      passwordLength: password.length
    });

    // Create user
    const user = await User.create({
      name,
      email,
      phone,
      password,
      role,
    });

    console.log('User created successfully:', {
      id: user._id,
      name: user.name,
      phone: user.phone
    });

    if (user) {
      const response = {
        _id: user._id,
        name: user.name,
        email: user.email,
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
      if (error.keyPattern.email) {
        return res.status(400).json({ message: 'Email already exists' });
      }
      if (error.keyPattern.phone) {
        return res.status(400).json({ message: 'Phone number already exists' });
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

    const { email, phone, password } = req.body;

    // Check if either email or phone is provided
    if (!email && !phone) {
      return res.status(400).json({ message: 'Please provide either email or phone number' });
    }

    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    // Find user by email or phone
    let user;
    if (email) {
      console.log('Attempting to find user by email:', email);
      user = await User.findOne({ email }).select('+password');
    } else {
      console.log('Attempting to find user by phone:', phone);
      user = await User.findOne({ phone }).select('+password');
    }

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
      email: user.email,
      phone: user.phone,
      role: user.role,
      token: generateToken(user._id),
      refreshToken: generateRefreshToken(user._id),
    };

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
      return res.status(401).json({ message: 'Refresh token is required' });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'default_refresh_secret');

    // Get user from the token
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({ message: 'Invalid refresh token' });
    }

    // Generate new tokens
    const newToken = generateToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    res.json({
      token: newToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    console.error(error);
    res.status(401).json({ message: 'Invalid refresh token' });
  }
};

module.exports = {
  registerUser,
  loginUser,
  refreshToken,
}; 