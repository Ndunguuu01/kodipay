require('dotenv').config({ path: __dirname + '/../.env' });
const express = require('express');
const path = require('path');
const dotenv = require('dotenv');
const http = require('http');
const socketio = require('socket.io');
const jwt = require('jsonwebtoken');

// Get the absolute path to the .env file
const envPath = path.resolve(process.cwd(), '.env');
console.log('Looking for .env file at:', envPath);

// Load environment variables from .env file
const result = dotenv.config({ path: envPath });

if (result.error) {
  console.error('Error loading .env file:', result.error);
  console.error('Current working directory:', process.cwd());
  console.error('Attempted .env path:', envPath);
  process.exit(1);
}

// Verify environment variables are loaded
console.log('Environment variables loaded successfully');
console.log('JWT_SECRET:', process.env.JWT_SECRET);
console.log('NODE_ENV:', process.env.NODE_ENV);


const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const compression = require('compression');
const pathModule = require('path');
const connectDB = require('./config/database');
const routes = require('./routes');
const passwordResetRoutes = require('./routes/passwordResetRoutes');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? process.env.FRONTEND_URL 
    : '*',
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression
app.use(compression());

// Connect to database
connectDB();

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date(),
    uptime: process.uptime(),
  });
});

// API routes
app.use('/api', routes);
app.use('/api/auth', passwordResetRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err : {},
  });
});

// Serve static files in production
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(pathModule.join(__dirname, '../build')));
  app.get('*', (req, res) => {
    res.sendFile(pathModule.join(__dirname, '../build/index.html'));
  });
}

const server = http.createServer(app);
const io = socketio(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Socket.io JWT authentication middleware
io.use((socket, next) => {
  const token = socket.handshake.query.token;
  if (!token) return next(new Error('Authentication error'));
  try {
    const user = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = user;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.user);

  socket.on('joinRoom', (roomId) => {
    socket.join(roomId);
  });

  socket.on('sendMessage', (data) => {
    // You can save the message to DB here if needed
    io.to(data.roomId).emit('newMessage', data);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

// Replace app.listen with server.listen
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
  });
}

module.exports = app;
