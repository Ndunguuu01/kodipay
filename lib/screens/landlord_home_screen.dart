import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);

    propertyProvider.fetchProperties(context);
    complaintProvider.fetchLandlordComplaints(authProvider.auth!.id, context);

    // Set initial selected index based on the current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedIndex(context);
    });
  }

  void _updateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    setState(() {
      if (location.startsWith('/landlord-home/properties')) {
        _selectedIndex = 1; // Properties tab
      } else if (location.startsWith('/landlord-home/messaging')) {
        _selectedIndex = 2; // Messages tab
      } else if (location.startsWith('/landlord-home/profile')) {
        _selectedIndex = 3; // Profile tab
      } else {
        _selectedIndex = 0; // Home tab
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/landlord-home');
        break;
      case 1:
        context.go('/landlord-home/properties');
        break;
      case 2:
        context.go('/landlord-home/complaints');
        break;
      case 3:
        context.go('/landlord-home/bills');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    // Update selected index whenever the widget rebuilds (e.g., after navigation)
    _updateSelectedIndex(context);

    // Quick stats
    final totalProperties = propertyProvider.properties.length;
    final occupiedRooms = propertyProvider.properties.fold<int>(0, (sum, p) => sum + (p.occupiedRooms ?? 0));
    final pendingComplaints = complaintProvider.complaints.where((c) => c.status != 'resolved').length;
    // For demo, unpaid bills is a placeholder
    const unpaidBills = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Dashboard'),
        backgroundColor: const Color(0xFF90CAF9),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/landlord-home/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              SizedBox(
                height: 110,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Properties', totalProperties.toString(), Icons.home, Colors.blue),
                      _buildStatCard('Occupied ', occupiedRooms.toString(), Icons.meeting_room, Colors.green),
                      _buildStatCard('Complaints', pendingComplaints.toString(), Icons.report_problem, Colors.orange),
                      _buildStatCard('Unpaid Bills', unpaidBills.toString(), Icons.receipt, Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShortcut(context, 'Add Property', Icons.add_business, '/landlord-home/properties/add-property'),
                  _buildShortcut(context, 'Assign Bill', Icons.assignment, '/landlord-home/bills'),
                  _buildShortcut(context, 'View Tenants', Icons.people, '/landlord-home/properties'),
                ],
              ),
              const SizedBox(height: 24),
              // Recent Activity Feed (latest 3 complaints)
              Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (complaintProvider.complaints.isEmpty)
                const Text('No recent activity.')
              else
                ...complaintProvider.complaints.take(3).map((c) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.report_problem, color: Colors.orange),
                    title: Text(c.title),
                    subtitle: Text('Status: ${c.status}'),
                  ),
                )),
              const SizedBox(height: 24),
              // Main navigation options
              Text('Main Sections', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMainNavCard(context, 'Properties', Icons.home, 1),
                  _buildMainNavCard(context, 'Complaints', Icons.report_problem, 2),
                  _buildMainNavCard(context, 'Bills', Icons.receipt, 3),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF90CAF9),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 80,
        height: 90,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(BuildContext context, String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 100,
          height: 80,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF90CAF9), size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainNavCard(BuildContext context, String label, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 100,
          height: 80,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF90CAF9), size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}