const express = require('express');
const router = express.Router();
const {
  createProperty,
  getProperties,
  updateProperty,
  deleteProperty,
  removeTenantFromRoom,
} = require('../controllers/propertyController');
const { protect } = require('../middleware/auth');

// Protect all routes
router.use(protect);

// Property routes
router.route('/')
  .post(createProperty)
  .get(getProperties);

router.route('/:id')
  .put(updateProperty)
  .delete(deleteProperty);

router.route('/:id/rooms/:roomId/remove-tenant')
  .put(removeTenantFromRoom);

module.exports = router;
