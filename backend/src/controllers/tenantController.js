const Tenant = require('../models/Tenant'); // Assuming tenantModel.js exists for tenant schema
const mongoose = require('mongoose');
const Property = require('../models/Property'); // Assuming propertyModel.js exists for property schema

// Create a new tenant (clean, minimal)
exports.createTenant = async (req, res) => {
  let session = null;
  let isReplicaSet = false;
  try {
    // Check if connected to a replica set
    const admin = mongoose.connection.db.admin();
    const info = await admin.command({ isMaster: 1 });
    isReplicaSet = !!info.setName;
  } catch (e) {
    // fallback: assume not a replica set
    isReplicaSet = false;
  }

  if (isReplicaSet) {
    session = await mongoose.startSession();
    session.startTransaction();
  }
  try {
    const { property, unit, name, phone, nationalId, leaseStart, leaseEnd } = req.body;
    if (!property || !unit || !name || !phone || !nationalId || !leaseStart || !leaseEnd) {
      if (isReplicaSet) { await session.abortTransaction(); session.endSession(); }
      return res.status(400).json({ message: 'Missing required tenant fields.' });
    }

    // Check for duplicate phone or nationalId
    const exists = isReplicaSet
      ? await Tenant.findOne({ $or: [{ phone }, { nationalId }] }).session(session)
      : await Tenant.findOne({ $or: [{ phone }, { nationalId }] });
    if (exists) {
      if (isReplicaSet) { await session.abortTransaction(); session.endSession(); }
      return res.status(400).json({ message: 'Phone or National ID already exists' });
    }

    // Find property and room
    const propertyDoc = isReplicaSet
      ? await Property.findById(property).session(session)
      : await Property.findById(property);
    if (!propertyDoc) {
      if (isReplicaSet) { await session.abortTransaction(); session.endSession(); }
      return res.status(404).json({ message: 'Property not found' });
    }

    let foundRoom = null;
    for (const floor of propertyDoc.floors) {
      for (const room of floor.rooms) {
        if (room._id.toString() === unit) {
          foundRoom = room;
          break;
        }
      }
      if (foundRoom) break;
    }

    if (!foundRoom) {
      if (isReplicaSet) { await session.abortTransaction(); session.endSession(); }
      return res.status(404).json({ message: 'Room not found' });
    }

    if (foundRoom.isOccupied) {
      if (isReplicaSet) { await session.abortTransaction(); session.endSession(); }
      return res.status(400).json({ message: 'Room is already occupied' });
    }

    // Create tenant
    let tenant;
    if (isReplicaSet) {
      tenant = await Tenant.create([
        { property, unit, name, phone, nationalId, leaseStart, leaseEnd }
      ], { session });
    } else {
      tenant = await Tenant.create({ property, unit, name, phone, nationalId, leaseStart, leaseEnd });
      tenant = [tenant];
    }

    // Mark room as occupied and set tenantId
    foundRoom.isOccupied = true;
    foundRoom.tenantId = tenant[0]._id;
    if (isReplicaSet) {
      await propertyDoc.save({ session });
    } else {
      await propertyDoc.save();
    }

    if (isReplicaSet) {
      await session.commitTransaction();
      session.endSession();
    }

    return res.status(201).json({ tenant: tenant[0] });
  } catch (error) {
    if (isReplicaSet && session) {
      await session.abortTransaction();
      session.endSession();
    }
    console.error('Error creating tenant:', error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get all tenants
exports.getTenants = async (req, res) => {
  try {
    const tenants = await Tenant.find();
    return res.status(200).json(tenants);
  } catch (error) {
    console.error('Error fetching tenants:', error);
    return res.status(500).json({ message: 'Server error fetching tenants' });
  }
};

// Get a single tenant by id
exports.getTenant = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid tenant id' });
    }
    const tenant = await Tenant.findById(id);
    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }
    return res.status(200).json(tenant);
  } catch (error) {
    console.error('Error fetching tenant:', error);
    return res.status(500).json({ message: 'Server error fetching tenant' });
  }
};

// Update a tenant by id
exports.updateTenant = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid tenant id' });
    }
    const updatedTenant = await Tenant.findByIdAndUpdate(id, req.body, { new: true });
    if (!updatedTenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }
    return res.status(200).json(updatedTenant);
  } catch (error) {
    console.error('Error updating tenant:', error);
    return res.status(500).json({ message: 'Server error updating tenant' });
  }
};

// Delete a tenant by id
exports.deleteTenant = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid tenant id' });
    }
    const deletedTenant = await Tenant.findByIdAndDelete(id);
    if (!deletedTenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }
    return res.status(200).json({ message: 'Tenant deleted successfully' });
  } catch (error) {
    console.error('Error deleting tenant:', error);
    return res.status(500).json({ message: 'Server error deleting tenant' });
  }
};

// Delete all tenants
exports.deleteAllTenants = async (req, res) => {
  try {
    await Tenant.deleteMany({});
    return res.status(200).json({ message: 'All tenants deleted successfully' });
  } catch (error) {
    console.error('Error deleting all tenants:', error);
    return res.status(500).json({ message: 'Server error deleting all tenants' });
  }
};
