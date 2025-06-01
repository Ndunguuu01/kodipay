const express = require('express');
const router = express.Router();
const {
  createProperty,
  getProperties,
  getProperty,
  updateProperty,
  deleteProperty,
  addUnit,
  updateUnit,
  deleteUnit,
} = require('../controllers/propertyController');
const { protect } = require('../middleware/auth');

// Protect all routes
router.use(protect);

// Property routes
router.route('/')
  .post(createProperty)
  .get(getProperties);

router.route('/:id')
  .get(getProperty)
  .put(updateProperty)
  .delete(deleteProperty);

// Unit routes
router.route('/:id/units')
  .post(addUnit);

router.route('/:id/units/:unitId')
  .put(updateUnit)
  .delete(deleteUnit);

module.exports = router; 