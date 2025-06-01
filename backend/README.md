# KodiPay Backend

This is the backend service for the KodiPay property management system. It provides APIs for managing properties, bills, and user authentication.

## Features

- User authentication with JWT
- Property management
- Unit management
- Bill generation and tracking
- Payment processing
- Role-based access control

## Prerequisites

- Node.js (v14 or higher)
- MongoDB
- npm or yarn

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/kodipay-backend.git
cd kodipay-backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the root directory with the following variables:
```
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/kodipay

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your_refresh_token_secret_here
JWT_REFRESH_EXPIRES_IN=30d

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=debug

# CORS
CORS_ORIGIN=http://localhost:3000

# Security
BCRYPT_SALT_ROUNDS=10
```

4. Start the development server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/refresh-token` - Refresh JWT token

### Properties
- `GET /api/properties` - Get all properties
- `POST /api/properties` - Create new property
- `GET /api/properties/:id` - Get single property
- `PUT /api/properties/:id` - Update property
- `DELETE /api/properties/:id` - Delete property
- `POST /api/properties/:id/units` - Add unit to property
- `PUT /api/properties/:id/units/:unitId` - Update unit
- `DELETE /api/properties/:id/units/:unitId` - Delete unit

### Bills
- `GET /api/bills` - Get all bills
- `POST /api/bills` - Create new bill
- `GET /api/bills/:id` - Get single bill
- `PUT /api/bills/:id` - Update bill
- `DELETE /api/bills/:id` - Delete bill
- `POST /api/bills/:id/payments` - Add payment to bill
- `GET /api/bills/stats` - Get bill statistics

## Development

### Scripts
- `npm run dev` - Start development server
- `npm start` - Start production server
- `npm test` - Run tests
- `npm run lint` - Run linter

### Project Structure
```
src/
  ├── config/         # Configuration files
  ├── controllers/    # Route controllers
  ├── middleware/     # Custom middleware
  ├── models/         # Database models
  ├── routes/         # API routes
  ├── utils/          # Utility functions
  └── app.js          # Express app
```

## Production Deployment

1. Build the application:
```bash
npm run build
```

2. Start the production server:
```bash
npm start
```

## Security

- JWT authentication
- Password hashing with bcrypt
- Rate limiting
- CORS protection
- Helmet security headers

## Error Handling

The API uses a consistent error response format:
```json
{
  "message": "Error message",
  "status": "error"
}
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License. 