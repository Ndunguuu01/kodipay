const Property = require('../models/Property');
const mongoose = require('mongoose');

// @desc    Create new property
// @route   POST /api/properties
// @access  Private
const createProperty = async (req, res) => {
  try {
    const property = await Property.create({
      ...req.body,
      landlordId: req.user._id,
    });

    res.status(201).json(property);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get all properties
// @route   GET /api/properties
// @access  Private
const getProperties = async (req, res) => {
  try {
    console.log('Getting properties for user:', req.user._id);
    const properties = await Property.find({
      landlordId: req.user._id,
    }).populate('landlordId', 'name email');

    console.log('Found properties:', properties);
    res.json(properties);
  } catch (error) {
    console.error('Error in getProperties:', error);
    res.status(500).json({ 
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update property
// @route   PUT /api/properties/:id
// @access  Private
const updateProperty = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is landlord
    if (property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    const updatedProperty = await Property.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.json(updatedProperty);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete property
// @route   DELETE /api/properties/:id
// @access  Private
const deleteProperty = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is landlord
    if (property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    await property.deleteOne();

    res.json({ message: 'Property removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const addUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is owner or manager
    if (
      property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    property.units.push(req.body);
    await property.save();

    res.status(201).json(property);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const updateUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is landlord
    if (property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    const unit = property.units.id(req.params.unitId);

    if (!unit) {
      return res.status(404).json({ message: 'Unit not found' });
    }

    Object.assign(unit, req.body);
    await property.save();

    res.json(property);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const deleteUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is landlord
    if (property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    property.units.pull(req.params.unitId);
    await property.save();

    res.json({ message: 'Unit removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Remove tenant from a room
// @route   PUT /api/properties/:id/rooms/:roomId/remove-tenant
// @access  Private
const removeTenantFromRoom = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Find the room in the floors
    let found = false;
    for (let floor of property.floors) {
      for (let room of floor.rooms) {
        if (room._id.toString() === req.params.roomId) {
          room.tenantId = null;
          room.isOccupied = false;
          found = true;
          break;
        }
      }
      if (found) break;
    }

    if (!found) {
      return res.status(404).json({ message: 'Room not found' });
    }

    await property.save();
    res.json({ message: 'Tenant unassigned from room', property });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const assignTenantToRoom = async (req, res) => {
  try {
    const { tenantId, roomId } = req.body;
    const propertyId = req.params.id;

    if (!tenantId || !roomId) {
      return res.status(400).json({ message: 'tenantId and roomId are required' });
    }

    const property = await Property.findById(propertyId);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is landlord
    if (property.landlordId && property.landlordId.toString && property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    // Find the room in the floors
    let found = false;
    for (let floor of property.floors) {
      for (let room of floor.rooms) {
        if (room._id.toString() === roomId) {
          if (room.isOccupied) {
            return res.status(400).json({ message: 'Room is already occupied' });
          }
          room.tenantId = tenantId;
          room.isOccupied = true;
          found = true;
          break;
        }
      }
      if (found) break;
    }

    if (!found) {
      return res.status(404).json({ message: 'Room not found' });
    }

    await property.save();
    res.json({ message: 'Tenant assigned to room', property });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createProperty,
  getProperties,
  updateProperty,
  deleteProperty,
  addUnit,
  updateUnit,
  deleteUnit,
  removeTenantFromRoom,
  assignTenantToRoom,
};
