const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Complaint = require('../models/Complaint');
const Property = require('../models/Property');

// Get all complaints for a landlord
router.get('/', protect, async (req, res) => {
  try {
    const complaints = await Complaint.find({ landlord: req.user._id })
      .populate('property', 'name address')
      .populate('tenant', 'name phone')
      .sort({ createdAt: -1 });
    res.json(complaints);
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(500).json({ message: 'Error fetching complaints' });
  }
});

// Get complaints for a specific tenant
router.get('/tenant/:tenantId', protect, async (req, res) => {
  try {
    const complaints = await Complaint.find({ tenant: req.params.tenantId })
      .populate('property', 'name address')
      .populate('landlord', 'name phone')
      .sort({ createdAt: -1 });
    res.json(complaints);
  } catch (error) {
    console.error('Error fetching tenant complaints:', error);
    res.status(500).json({ message: 'Error fetching tenant complaints' });
  }
});

// Create a new complaint
router.post('/', protect, async (req, res) => {
  try {
    const { title, description, property: propertyId } = req.body;

    // Verify the property exists and belongs to the landlord
    const property = await Property.findOne({ _id: propertyId, landlord: req.user._id });
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    const complaint = new Complaint({
      title,
      description,
      property: propertyId,
      tenant: req.user._id,
      landlord: property.landlord
    });

    await complaint.save();
    res.status(201).json(complaint);
  } catch (error) {
    console.error('Error creating complaint:', error);
    res.status(500).json({ message: 'Error creating complaint' });
  }
});

// Update complaint status
router.put('/:id', protect, async (req, res) => {
  try {
    const { status } = req.body;
    const complaint = await Complaint.findById(req.params.id);

    if (!complaint) {
      return res.status(404).json({ message: 'Complaint not found' });
    }

    // Only landlord can update status
    if (complaint.landlord.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to update this complaint' });
    }

    complaint.status = status;
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    console.error('Error updating complaint:', error);
    res.status(500).json({ message: 'Error updating complaint' });
  }
});

// Delete a complaint
router.delete('/:id', protect, async (req, res) => {
  try {
    const complaint = await Complaint.findById(req.params.id);

    if (!complaint) {
      return res.status(404).json({ message: 'Complaint not found' });
    }

    // Only landlord or tenant who created the complaint can delete it
    if (complaint.landlord.toString() !== req.user._id.toString() && 
        complaint.tenant.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this complaint' });
    }

    await complaint.deleteOne();
    res.json({ message: 'Complaint deleted successfully' });
  } catch (error) {
    console.error('Error deleting complaint:', error);
    res.status(500).json({ message: 'Error deleting complaint' });
  }
});

module.exports = router; 