const Lease = require('../models/leaseModel'); // Assuming leaseModel.js exists
const asyncHandler = require('express-async-handler');

// @desc    Get leases for a tenant
// @route   GET /api/leases/tenant/:tenantId
// @access  Private
const getLeasesByTenant = asyncHandler(async (req, res) => {
  const tenantId = req.params.tenantId;
  if (!tenantId) {
    res.status(400);
    throw new Error('Tenant ID is required');
  }

  const leases = await Lease.find({ tenantId });
  if (!leases) {
    res.status(404);
    throw new Error('Leases not found for tenant');
  }

  res.json(leases);
});

// Additional CRUD operations can be added here as needed

module.exports = {
  getLeasesByTenant,
};
