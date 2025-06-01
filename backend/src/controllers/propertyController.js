const Property = require('../models/Property');

// @desc    Create new property
// @route   POST /api/properties
// @access  Private
const createProperty = async (req, res) => {
  try {
    const property = await Property.create({
      ...req.body,
      owner: req.user._id,
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
    const properties = await Property.find({
      $or: [
        { owner: req.user._id },
        { manager: req.user._id },
      ],
    }).populate('owner', 'name email');

    res.json(properties);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single property
// @route   GET /api/properties/:id
// @access  Private
const getProperty = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id)
      .populate('owner', 'name email')
      .populate('manager', 'name email')
      .populate('units.tenant', 'name email');

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is owner or manager
    if (
      property.owner._id.toString() !== req.user._id.toString() &&
      property.manager?._id.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    res.json(property);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
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

    // Check if user is owner or manager
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
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

    // Check if user is owner
    if (property.owner.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    await property.remove();

    res.json({ message: 'Property removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Add unit to property
// @route   POST /api/properties/:id/units
// @access  Private
const addUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is owner or manager
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
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

// @desc    Update unit
// @route   PUT /api/properties/:id/units/:unitId
// @access  Private
const updateUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is owner or manager
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
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

// @desc    Delete unit
// @route   DELETE /api/properties/:id/units/:unitId
// @access  Private
const deleteUnit = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if user is owner or manager
    if (
      property.owner.toString() !== req.user._id.toString() &&
      property.manager?.toString() !== req.user._id.toString()
    ) {
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

module.exports = {
  createProperty,
  getProperties,
  getProperty,
  updateProperty,
  deleteProperty,
  addUnit,
  updateUnit,
  deleteUnit,
}; 