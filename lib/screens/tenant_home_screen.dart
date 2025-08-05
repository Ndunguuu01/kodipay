import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../providers/complaint_provider.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final leaseProvider = context.read<LeaseProvider>();
    final propertyProvider = context.read<PropertyProvider>();
    final tenantProvider = context.read<TenantProvider>();
    final complaintProvider = context.read<ComplaintProvider>();

    if (authProvider.auth != null && authProvider.auth!.token != null) {
      await leaseProvider.fetchLeases(
        authProvider.auth!.id,
        authProvider.auth!.token!,
      );
      await propertyProvider.fetchProperties(context);
      await tenantProvider.fetchTenants();
      await complaintProvider.fetchComplaints();
    } else {
      print('No auth data available, cannot fetch data');
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/tenant-home/messaging')) return 1;
    if (location.startsWith('/tenant-home/complaints')) return 2;
    if (location.startsWith('/tenant-home/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final String currentLocation = GoRouterState.of(context).matchedLocation;
    String targetRoute;

    switch (index) {
      case 0:
        targetRoute = '/tenant-home';
        break;
      case 1:
        targetRoute = '/tenant-home/messaging';
        break;
      case 2:
        targetRoute = '/tenant-home/complaints';
        break;
      case 3:
        targetRoute = '/tenant-home/profile';
        break;
      default:
        targetRoute = '/tenant-home';
    }

    // Only navigate if we're not already on the target route
    if (currentLocation != targetRoute) {
      context.go(targetRoute);
    }
  }

  int? _calculatedSelectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculatedSelectedIndex = _calculateSelectedIndex(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final leaseProvider = Provider.of<LeaseProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    final user = authProvider.auth;
    final userName = (user?.firstName != null && user?.lastName != null)
        ? '${user!.firstName} ${user.lastName}'
        : (user?.firstName ?? user?.name ?? 'User');
    final profilePhotoUrl = user?.profilePicture;
    String greeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }

    // Find the tenant's assigned room
    RoomModel? assignedRoom;
    PropertyModel? assignedProperty;
    int? floorNumber;
    for (var property in propertyProvider.properties) {
      for (var floor in property.floors) {
        for (var room in floor.rooms) {
          if (room.tenantId == authProvider.auth?.id) {
            assignedRoom = room;
            assignedProperty = property;
            floorNumber = floor.floorNumber;
            break;
          }
        }
        if (assignedRoom != null) break;
      }
      if (assignedRoom != null) break;
    }

    // Use _calculatedSelectedIndex instead of updating _selectedIndex here
    final selectedIndex = _calculatedSelectedIndex ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile photo or initials
                      profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(profilePhotoUrl),
                            )
                          : CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                userName.isNotEmpty
                                    ? userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            greeting(),
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Room Information Card
            if (assignedRoom != null && assignedProperty != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Room',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Property', assignedProperty.name),
                        _buildInfoRow('Room Number', assignedRoom.roomNumber),
                        _buildInfoRow('Floor', 'Floor ${floorNumber ?? "N/A"}'),
                        _buildInfoRow('Status', assignedRoom.isOccupied ? 'Occupied' : 'Vacant'),
                      ],
                    ),
                  ),
                ),
              ),

            // Lease Information
            if (leaseProvider.leases.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lease Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var lease in leaseProvider.leases)
                          Column(
                            children: [
                              _buildInfoRow('Lease Type', lease.leaseType),
                              _buildInfoRow('Amount', 'KES ${lease.amount}'),
                              _buildInfoRow('Due Date', lease.dueDate),
                              _buildInfoRow('Status', lease.status),
                              const Divider(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xFF90CAF9),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
