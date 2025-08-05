import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/providers/bill_provider.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Provider.of<TenantProvider>(context, listen: false).fetchTenants();
      final tenants = Provider.of<TenantProvider>(context, listen: false).tenants;
      print('Fetched tenants:');
      for (var tenant in tenants) {
        print('Tenant: id=[32m[1m[4m[7m[5m[3m[9m[8m[6m[0m[1m[4m[7m[5m[3m[9m[8m[6m[0m${tenant.id}[0m, name=${tenant.fullName}, phone=${tenant.phoneNumber}');
      }
    });
  }

  List<TenantModel> _getFilteredTenants(List<TenantModel> tenants) {
    return tenants.where((tenant) {
      final matchesSearch = tenant.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tenant.phoneNumber.contains(_searchQuery);
      
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Active' && tenant.status == 'active') ||
          (_selectedFilter == 'Inactive' && tenant.status == 'inactive') ||
          (_selectedFilter == 'Pending' && tenant.status == 'pending');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TenantProvider>(
        builder: (context, tenantProvider, child) {
          if (tenantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tenantProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${tenantProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      tenantProvider.fetchTenants();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredTenants = _getFilteredTenants(tenantProvider.tenants);

          return Column(
            children: [
              // Header Section with Gradient
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF90CAF9),
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    // Title
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tenant Management',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${filteredTenants.length} ${filteredTenants.length == 1 ? 'Tenant' : 'Tenants'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Search and Filter Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tenants...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF90CAF9)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          _buildFilterChip('Active'),
                          _buildFilterChip('Inactive'),
                          _buildFilterChip('Pending'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tenant List
              Expanded(
                child: filteredTenants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tenants found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTenants.length,
                        itemBuilder: (context, index) {
                          final tenant = filteredTenants[index];
                          return _buildTenantCard(tenant);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/landlord-home/tenants/add');
        },
        backgroundColor: const Color(0xFF90CAF9),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Tenant'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF90CAF9).withOpacity(0.2),
        checkmarkColor: const Color(0xFF90CAF9),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF90CAF9) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF90CAF9) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(TenantModel tenant) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);

    // Get property name and room number
    String propertyName = 'Unassigned';
    String roomName = 'Unassigned';
    String floorName = 'Unassigned';

    if (tenant.property != null) {
      final property = propertyProvider.properties.firstWhere(
        (p) => p.id == tenant.property!.id,
        orElse: () => PropertyModel(
          id: '',
          name: '',
          address: '',
          rentAmount: 0,
          totalRooms: 0,
          occupiedRooms: 0,
          floors: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      propertyName = property.name;

      // Find room and floor by tenant.unit
      if (tenant.unit != null && tenant.unit!.isNotEmpty) {
        for (var floor in property.floors) {
          final rooms = floor.rooms.where((r) => r.id == tenant.unit).toList();
          if (rooms.isNotEmpty) {
            roomName = rooms.first.roomNumber;
            floorName = floor.floorNumber.toString();
            break;
          }
        }
      }
    } else if (tenant.property is Map && tenant.property != null && (tenant.property as Map)['_id'] != null) {
      // Fallback for raw JSON data
      final property = propertyProvider.properties.firstWhere(
        (p) => p.id == (tenant.property as Map)['_id'],
        orElse: () => PropertyModel(
          id: '',
          name: '',
          address: '',
          rentAmount: 0,
          totalRooms: 0,
          occupiedRooms: 0,
          floors: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      propertyName = property.name;

      // Find room and floor by tenant.unit
      if (tenant.unit != null && tenant.unit!.isNotEmpty) {
        for (var floor in property.floors) {
          final rooms = floor.rooms.where((r) => r.id == tenant.unit).toList();
          if (rooms.isNotEmpty) {
            roomName = rooms.first.roomNumber;
            floorName = floor.floorNumber.toString();
            break;
          }
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF90CAF9).withOpacity(0.1),
                  child: Text(
                    tenant.fullName.isNotEmpty
                        ? tenant.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF90CAF9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.fullName.isNotEmpty
                            ? tenant.fullName
                            : 'Unnamed Tenant',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.phoneNumber,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Property: $propertyName',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Room: $roomName',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Floor: $floorName',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(tenant.status ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  Icons.home,
                  tenant.property != null ? 'Assigned' : 'Unassigned',
                  tenant.property != null ? Colors.green : Colors.orange,
                ),
                _buildInfoChip(
                  Icons.payment,
                  tenant.paymentStatus ?? 'Unknown',
                  _getPaymentStatusColor(tenant.paymentStatus),
                ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          tooltip: 'View Payment History / Download Invoice',
                          onPressed: () {
                            _showPaymentHistoryDialog(context, tenant);
                          },
                        ),
                        if (tenant.property != null && tenant.unit != null && tenant.unit!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.orange),
                            tooltip: 'Unassign Tenant',
                            onPressed: () async {
                              await _unassignTenant(context, tenant);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // TODO: Show tenant actions menu
                          },
                        ),
                      ],
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentHistoryDialog(BuildContext context, TenantModel tenant) async {
    showDialog(
      context: context,
      builder: (context) {
        return PaymentHistoryDialog(tenant: tenant);
      },
    );
  }

  Future<void> _unassignTenant(BuildContext context, TenantModel tenant) async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    String? propertyId;
    String? roomId;
    if (tenant.property != null) {
      if (tenant.property is PropertyModel) {
        propertyId = tenant.property!.id;
      } else if (tenant.property is Map && (tenant.property as Map)['id'] != null) {
        propertyId = (tenant.property as Map)['id'];
      } else if (tenant.property is Map && (tenant.property as Map)['_id'] != null) {
        propertyId = (tenant.property as Map)['_id'];
      }
    }
    if (tenant.unit != null && tenant.unit!.isNotEmpty) {
      roomId = tenant.unit;
    }
    if (propertyId != null && roomId != null) {
      await propertyProvider.removeTenantFromRoom(
        propertyId: propertyId,
        roomId: roomId,
        messageProvider: messageProvider,
      );
      // Delete tenant from DB
      await tenantProvider.deleteTenant(tenant.id, context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant unassigned and deleted successfully')),
      );
      // Optionally refresh tenants list here
      tenantProvider.fetchTenants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unassign tenant: missing property or room info')),
      );
    }
  }
}

class PaymentHistoryDialog extends StatelessWidget {
  final TenantModel tenant;
  const PaymentHistoryDialog({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PaymentHistoryList(tenantId: tenant.id),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Invoice (PDF)'),
                onPressed: () {
                  // TODO: Implement PDF download
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF download coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  final String tenantId;
  const _PaymentHistoryList({required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BillModel>>(
      future: Provider.of<BillProvider>(context, listen: false).fetchTenantBills(tenantId, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No payment history found.');
        }
        final bills = snapshot.data!;
        return SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return ListTile(
                title: Text(bill.description ?? 'Bill'),
                subtitle: Text('Amount: KES ${bill.amount} | Status: ${bill.status.name}'),
                trailing: Text('${bill.dueDate.toLocal()}'.split(' ')[0]),
              );
            },
          ),
        );
      },
    );
  }
} 