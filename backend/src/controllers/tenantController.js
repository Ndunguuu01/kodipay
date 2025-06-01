const Tenant = require('../models/Tenant');
const Property = require('../models/Property');

// @desc    Create new tenant
// @route   POST /api/tenants
// @access  Private
const createTenant = async (req, res) => {
  try {
    const { property: propertyId, unit: unitId } = req.body;

    // Verify property exists and user has access
    const property = await Property.findById(propertyId);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    // Verify unit exists
    const unit = property.units.id(unitId);
    if (!unit) {
      return res.status(404).json({ message: 'Unit not found' });
    }

    const tenant = await Tenant.create(req.body);

    res.status(201).json(tenant);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get all tenants
// @route   GET /api/tenants
// @access  Private
const getTenants = async (req, res) => {
  try {
    const tenants = await Tenant.find({
      $or: [
        { 'property.owner': req.user._id },
        { 'property.manager': req.user._id },
      ],
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

    // Check if user has access
    const property = await Property.findById(tenant.property);
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    await tenant.remove();

    res.json({ message: 'Tenant removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createTenant,
  getTenants,
  getTenant,
  updateTenant,
  deleteTenant,
}; 