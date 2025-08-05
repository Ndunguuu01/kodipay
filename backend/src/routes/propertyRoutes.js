const express = require('express');
const router = express.Router();
const {
  createProperty,
  getProperties,
  updateProperty,
  deleteProperty,
  addUnit,
  updateUnit,
  deleteUnit,
  removeTenantFromRoom,
  assignTenantToRoom,
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

router.route('/:id/units')
  .post(addUnit);

router.route('/:id/units/:unitId')
  .put(updateUnit)
  .delete(deleteUnit);

router.route('/:id/rooms/:roomId/remove-tenant')
  .put(removeTenantFromRoom);

router.route('/:id/assign-tenant')
  .put(assignTenantToRoom);

module.exports = router;
