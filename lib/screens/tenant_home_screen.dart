import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';

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

    // Fetch lease data safely after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
      if (authProvider.auth != null) {
        leaseProvider.fetchLeases(authProvider.auth!.id,authProvider.auth!.token);
      } else {
        print('No auth data available, cannot fetch lease');
      }
    });
  }

  // Dynamic greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Already on TenantHomeScreen
        break;
      case 1:
        context.go('/tenant-home/messaging');
        break;
      case 2:
        context.go('/tenant-home/complaints');
        break;
      case 3:
        context.go('/tenant-home/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final leaseProvider = Provider.of<LeaseProvider>(context);
    final userName = authProvider.auth?.name ?? "User";

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: const BoxDecoration(
              color: Color(0xFF90CAF9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Stack(
              children: [
                // KodiPay text
                const Positioned(
                  top: 40,
                  left: 20,
                  child: Text(
                    'KodiPay',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Settings icon
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {
                      context.go('/tenant-home/settings');
                    },
                  ),
                ),
                // User greeting
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.pink,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.payment,
                  label: 'Payment',
                  onTap: () => context.go('/tenant-home/payment'),
                ),
                _buildActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Bills',
                  onTap: () => context.go('/tenant-home/bills'),
                ),
                _buildActionButton(
                  icon: Icons.receipt,
                  label: 'Receipts',
                  onTap: () => context.go('/tenant-home/receipts'),
                ),
              ],
            ),
          ),
          // Complaints Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GestureDetector(
              onTap: () => context.go('/tenant-home/complaints'),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'complaints',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          // Lease Information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: authProvider.auth == null
            ? const Center(child: Text('Please log in to view your dashboard'))
            : leaseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : leaseProvider.leases.isEmpty
                    ? Center(child: Text(leaseProvider.error ?? 'No lease information available'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lease Information',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Display the first lease (or adjust for multiple leases if needed)
                          _buildLeaseInfoRow('Lease Type', leaseProvider.leases.first.leaseType),
                          _buildLeaseInfoRow('Amount', 'Kes ${leaseProvider.leases.first.amount.toStringAsFixed(0)}'),
                          _buildLeaseInfoRow('Start date', leaseProvider.leases.first.startDate),
                          _buildLeaseInfoRow('Due Date', leaseProvider.leases.first.dueDate),
                          _buildLeaseInfoRow('Balance', 'Kes ${leaseProvider.leases.first.balance.toStringAsFixed(0)}'),
                          _buildLeaseInfoRow('Payable Amount', 'Kes ${leaseProvider.leases.first.payableAmount.toStringAsFixed(0)}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              GoRouter.of(context).push('/tenant-home/complaint');
                            },
                            child: const Text('File a Complaint'),
                          ),
                        ],
                      ),
      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF90CAF9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
          
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
