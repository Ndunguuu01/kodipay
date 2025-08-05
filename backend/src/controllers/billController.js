const Bill = require('../models/Bill');
const Property = require('../models/Property');

// @desc    Create new bill
// @route   POST /api/bills
// @access  Private
const createBill = async (req, res) => {
  try {
    const { property: propertyId, unit: unitId, tenant: tenantId, amount, dueDate, type, description } = req.body;

    // Verify property exists and user has access
    const property = await Property.findById(propertyId);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    if (
      (property.landlordId && property.landlordId.toString() !== req.user._id.toString())
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    // Verify unit exists by searching through floors and rooms
    let unitFound = false;
    let roomDetails = null;
    
    for (const floor of property.floors) {
      const room = floor.rooms.find(r => r._id.toString() === unitId);
      if (room) {
        unitFound = true;
        roomDetails = room;
        break;
      }
    }
    
    if (!unitFound) {
      return res.status(404).json({ message: 'Room/Unit not found' });
    }

    // Create the bill with correct structure
    const bill = await Bill.create({
      property: propertyId,
      unit: unitId,
      tenant: tenantId,
      amount: amount,
      dueDate: new Date(dueDate),
      type: type,
      description: description,
      createdBy: req.user._id,
    });

    res.status(201).json(bill);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get all bills
// @route   GET /api/bills
// @access  Private
const getBills = async (req, res) => {
  try {
    const bills = await Bill.find({
      $or: [
        { 'property.owner': req.user._id },
        { 'property.manager': req.user._id },
        { tenant: req.user._id },
      ],
    })
      .populate('property', 'name')
      .populate('tenant', 'name email')
      .populate('createdBy', 'name');

    res.json(bills);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single bill
// @route   GET /api/bills/:id
// @access  Private
const getBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id)
      .populate('property', 'name')
      .populate('tenant', 'name email')
      .populate('createdBy', 'name');

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Check if user has access
    const property = await Property.findById(bill.property);
    if (
      (property.landlordId && property.landlordId.toString() !== req.user._id.toString()) &&
      bill.tenant.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    res.json(bill);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update bill
// @route   PUT /api/bills/:id
// @access  Private
const updateBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Check if user has access
    const property = await Property.findById(bill.property);
    if (
      property.landlordId && property.landlordId.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    const updatedBill = await Bill.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.json(updatedBill);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete bill
// @route   DELETE /api/bills/:id
// @access  Private
const deleteBill = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Check if user has access
    const property = await Property.findById(bill.property);
    if (
      property.landlordId && property.landlordId.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    await bill.remove();

    res.json({ message: 'Bill removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Add payment to bill
// @route   POST /api/bills/:id/payments
// @access  Private
const addPayment = async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Check if user has access
    const property = await Property.findById(bill.property);
    if (
      (property.landlordId && property.landlordId.toString() !== req.user._id.toString()) &&
      bill.tenant.toString() !== req.user._id.toString()
    ) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    bill.paymentHistory.push({
      ...req.body,
      date: new Date(),
    });

    bill.updateStatus();
    await bill.save();

    res.status(201).json(bill);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get bill statistics
// @route   GET /api/bills/stats
// @access  Private
const getBillStats = async (req, res) => {
  try {
    const stats = await Bill.aggregate([
      {
        $match: {
          $or: [
            { 'property.owner': req.user._id },
            { 'property.manager': req.user._id },
            { tenant: req.user._id },
          ],
        },
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
        },
      },
    ]);

    res.json(stats);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createBill,
  getBills,
  getBill,
  updateBill,
  deleteBill,
  addPayment,
  getBillStats,
}; 