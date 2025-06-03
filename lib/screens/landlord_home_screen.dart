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
  bool? _authChecked;

  @override
  void initState() {
    super.initState();
    // The logic that was here will be moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex(context);

    // Call checkAndRestoreAuth here to ensure AuthProvider state is updated
    // and ApiService has the latest tokens after initialization or hot restart.
    // Only run this once after the initial dependencies change.
    if (_authChecked == null || !_authChecked!) {
      _authChecked = true;
      _checkAndInitializeAuth();
    }

    // Move the addPostFrameCallback logic here
    // This will be called after initState and whenever dependencies change
    if (!mounted) return;

    // Check if user is authenticated and fetch data
    _initializeData();
  }

  Future<void> _checkAndInitializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    // Check if user is authenticated
    if (authProvider.auth == null) {
      // Try to restore auth state
      final restored = await authProvider.checkAndRestoreAuth();
      if (!restored && mounted) {
        context.go('/login');
        return;
      }
    }
    // Fetch data after auth is checked and potentially restored
    // Defer the call to _initializeData to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
         _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      // Check if user is authenticated (redundant check but good practice)
      final auth = context.read<AuthProvider>().auth;
      if (auth == null) {
         // Should ideally not happen if _checkAndInitializeAuth worked
         if (mounted) context.go('/login');
         return;
      }

      // Only fetch data if we're still mounted and authenticated
      if (mounted) {
        // Check if data has already been loaded to avoid unnecessary fetches
        if (context.read<PropertyProvider>().properties.isEmpty) {
           await context.read<PropertyProvider>().fetchProperties(context);
        }
        if (context.read<ComplaintProvider>().complaints.isEmpty) {
           await context.read<ComplaintProvider>().fetchLandlordComplaints(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
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

    final String currentLocation = GoRouterState.of(context).matchedLocation;
    String targetRoute;

    switch (index) {
      case 0:
        targetRoute = '/landlord-home';
        break;
      case 1:
        targetRoute = '/landlord-home/properties';
        break;
      case 2:
        targetRoute = '/landlord-home/complaints';
        break;
      case 3:
        targetRoute = '/landlord-home/bills';
        break;
      default:
        targetRoute = '/landlord-home';
    }

    // Only navigate if we're not already on the target route
    if (currentLocation != targetRoute) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              try {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, PropertyProvider, ComplaintProvider>(
        builder: (context, authProvider, propertyProvider, complaintProvider, child) {
          // Show loading indicator if any provider is loading
          if (propertyProvider.isLoading || complaintProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if any provider has an error
          if (propertyProvider.errorMessage != null || complaintProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    propertyProvider.errorMessage ?? complaintProvider.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading data
                      if (mounted) {
                        propertyProvider.fetchProperties(context);
                        complaintProvider.fetchLandlordComplaints(context);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Quick stats
          final totalProperties = propertyProvider.properties.length;
          final occupiedRooms = propertyProvider.properties.fold<int>(0, (sum, p) => sum + (p.occupiedRooms ?? 0));
          final pendingComplaints = complaintProvider.complaints.where((c) => c.status != 'resolved').length;
          // For demo, unpaid bills is a placeholder
          const unpaidBills = 0;

          return SingleChildScrollView(
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
          );
        },
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