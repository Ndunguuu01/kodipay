require('dotenv').config({ path: __dirname + '/../.env' });

// Verify environment variables are loaded immediately after loading .env
console.log('Environment variables loaded successfully');
console.log('JWT_SECRET (from app.js):', process.env.JWT_SECRET);
console.log('NODE_ENV (from app.js):', process.env.NODE_ENV);

const express = require('express');
const path = require('path');
// const dotenv = require('dotenv'); // This line is no longer needed
const http = require('http');
const socketio = require('socket.io');
const jwt = require('jsonwebtoken');

// Removed redundant .env loading block
// const envPath = path.resolve(process.cwd(), '.env');
// console.log('Looking for .env file at:', envPath);
// const result = dotenv.config({ path: envPath });
// if (result.error) {
//   console.error('Error loading .env file:', result.error);
//   console.error('Current working directory:', process.cwd());
//   console.error('Attempted .env path:', envPath);
//   process.exit(1);
// } 