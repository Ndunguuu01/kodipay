const Tenant = require('../models/Tenant');
const Property = require('../models/Property');
const User = require('../models/User');

// @desc    Create new tenant
// @route   POST /api/tenants
// @access  Private
const createTenant = async (req, res) => {
  try {
    console.log('createTenant called with body:', req.body);
    console.log('User from request:', req.user);

    const { property: propertyId, unit: unitId } = req.body;

    if (!req.user || !req.user._id) {
      console.error('User not found in request:', req.user);
      return res.status(401).json({ message: 'User not authenticated' });
    }

    // Verify property exists and user has access
    const property = await Property.findById(propertyId);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    console.log('Property found:', {
      id: property._id,
      landlordId: property.landlordId,
      user: req.user._id
    });

    if (
      property.landlordId.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    // Verify unit exists and is not occupied
    let unit = null;
    let floorIndex = -1;
    let roomIndex = -1;

    for (let i = 0; i < property.floors.length; i++) {
      const floor = property.floors[i];
      const roomIdx = floor.rooms.findIndex(room => room._id.toString() === unitId);
      if (roomIdx !== -1) {
        unit = floor.rooms[roomIdx];
        floorIndex = i;
        roomIndex = roomIdx;
        break;
      }
    }

    if (!unit) {
      return res.status(404).json({ message: 'Unit not found' });
    }

    if (unit.isOccupied) {
      return res.status(400).json({ message: 'Unit is already occupied' });
    }

    // Create the tenant
    const tenant = await Tenant.create(req.body);

    // Update the room's status
    property.floors[floorIndex].rooms[roomIndex].isOccupied = true;
    property.floors[floorIndex].rooms[roomIndex].tenantId = tenant._id;
    await property.save();

    res.status(201).json(tenant);
  } catch (error) {
    console.error('Error in createTenant:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get all tenants
// @route   GET /api/tenants
// @access  Private
const getTenants = async (req, res) => {
  try {
    // Find all properties owned or managed by the user
    const properties = await Property.find({
      $or: [
        { landlordId: req.user._id },
        { manager: req.user._id }
      ]
    });
    const propertyIds = properties.map(p => p._id);

    // Only return tenants with a valid property and unit
    const tenants = await Tenant.find({
      property: { $in: propertyIds },
      unit: { $ne: null },
    }).populate('property', 'name');

    res.json(tenants);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single tenant
// @route   GET /api/tenants/:id
// @access  Private
const getTenant = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.params.id).populate('property', 'name');

    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }

    // Check if user has access
    const property = await Property.findById(tenant.property);
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    res.json(tenant);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update tenant
// @route   PUT /api/tenants/:id
// @access  Private
const updateTenant = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.params.id);

    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }

    // Check if user has access
    const property = await Property.findById(tenant.property);
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    const updatedTenant = await Tenant.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.json(updatedTenant);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete tenant
// @route   DELETE /api/tenants/:id
// @access  Private
const deleteTenant = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.params.id);

    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }

    // Check if property exists
    const property = await Property.findById(tenant.property);
    if (!property) {
      // Property not found, allow tenant deletion
      await Tenant.findByIdAndDelete(tenant._id);
      // Log tenant for debugging
      console.log('Deleting associated user for tenant:', tenant);
      // Only try to delete user if email or phone exists
      if (tenant.email || tenant.phone) {
        await User.deleteOne({
          $or: [
            ...(tenant.email ? [{ email: tenant.email }] : []),
            ...(tenant.phone ? [{ phone: tenant.phone }] : []),
          ]
        });
      } else {
        console.warn('Tenant has no email or phone, cannot delete associated user.');
      }
      return res.json({ message: 'Tenant and user removed (property not found)' });
    }

    // Check if user is landlord
    if (property.landlordId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    await Tenant.findByIdAndDelete(tenant._id);
    // Log tenant for debugging
    console.log('Deleting associated user for tenant:', tenant);
    // Only try to delete user if email or phone exists
    if (tenant.email || tenant.phone) {
      await User.deleteOne({
        $or: [
          ...(tenant.email ? [{ email: tenant.email }] : []),
          ...(tenant.phone ? [{ phone: tenant.phone }] : []),
        ]
      });
    } else {
      console.warn('Tenant has no email or phone, cannot delete associated user.');
    }

    res.json({ message: 'Tenant and user removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  createTenant,
  getTenants,
  getTenant,
  updateTenant,
  deleteTenant,
}; 