import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';
import 'package:kodipay/utils/logger.dart';
import 'dart:async';

class LandlordHomeScreen extends StatefulWidget {
  final Widget? child;

  const LandlordHomeScreen({super.key, this.child});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  bool? _authChecked;
  int _currentChartIndex = 0;
  late PageController _pageController;
  Timer? _carouselTimer;
  bool _isPageViewMounted = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Initialize carousel after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isPageViewMounted = true;
        });
        _startCarousel();
      }
    });
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isPageViewMounted && mounted && _pageController.hasClients) {
        if (_currentChartIndex < 2) {
          _currentChartIndex++;
        } else {
          _currentChartIndex = 0;
        }
        _pageController.animateToPage(
          _currentChartIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex(context);

    if (_authChecked == null || !_authChecked!) {
      _authChecked = true;
      _checkAndInitializeAuth();
    }

    if (!mounted) return;

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeData();
        }
      });
    }
  }

  Future<void> _checkAndInitializeAuth() async {
    final authProvider = context.read<AuthProvider>();

    // Only attempt to restore auth if currently not authenticated
    if (authProvider.auth == null) {
      Logger.info('Attempting to check and restore auth state.');
      await authProvider.initialize();

      if (authProvider.auth == null && mounted) {
        Logger.warning('Auth state could not be restored, navigating to login.');
        // Use a post-frame callback for navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login');
        });
        return;
      }
      if (authProvider.auth != null) {
        Logger.info('Auth state restored successfully.');
      }
    }

    // If authenticated (either initially or after restoration), proceed to fetch data
    if (authProvider.auth != null && mounted) {
      Logger.info('Authenticated, proceeding to initialize data.');
      // Defer the call to _initializeData to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeData();
        }
      });
    } else if (mounted) {
      // Fallback if auth is still null after checkAndRestoreAuth (shouldn't happen if checkAndRestoreAuth works)
      Logger.warning('Auth is still null after check, navigating to login.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    try {
      final propertyProvider = context.read<PropertyProvider>();
      final complaintProvider = context.read<ComplaintProvider>();

      // Always refresh properties after login to ensure fresh data
      await propertyProvider.refreshProperties(context);
      
      if (complaintProvider.complaints.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          complaintProvider.fetchComplaints();
        });
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
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    setState(() {
      if (location.startsWith('/landlord-home/tenants')) {
        // _selectedIndex = 1;
      } else if (location.startsWith('/landlord-home/complaints')) {
        // _selectedIndex = 2;
      } else if (location.startsWith('/landlord-home/profile')) {
        // _selectedIndex = 3;
      } else {
        // _selectedIndex = 0; // Dashboard
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final user = authProvider.auth;
    final userName = (user?.firstName != null && user?.lastName != null)
        ? '${user!.firstName} ${user.lastName}'
        : (user?.firstName ?? user?.name ?? 'User');
    final profilePhotoUrl = user?.profilePicture;
    final isLandlord = user?.role == 'landlord';

    String greeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () => context.go('/landlord-home/messages'),
                tooltip: 'Messages',
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => context.go('/landlord-home/settings'),
                tooltip: 'Settings',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
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
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Cards
                  _buildQuickStatsCards(propertyProvider, complaintProvider),
                  const SizedBox(height: 24),
                  
                  // Charts Carousel
                  SizedBox(
                    height: 300,
                    child: PageView(
                      controller: _pageController,
                      children: [
                        _buildOccupancyChart(propertyProvider),
                        _buildRevenueChart(propertyProvider),
                        _buildComplaintsChart(complaintProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Activity
                  _buildRecentActivity(propertyProvider, complaintProvider),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isLandlord
          ? FloatingActionButton(
              onPressed: () => context.go('/landlord-home/properties/add'),
              tooltip: 'Add Property',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: null,
    );
  }

  Widget _buildQuickStatsCards(PropertyProvider propertyProvider, ComplaintProvider complaintProvider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Properties',
          propertyProvider.properties.length.toString(),
          Icons.home,
          Colors.blue,
        ),
        _buildStatCard(
          'Occupied Units',
          _calculateOccupiedUnits(propertyProvider).toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Pending Complaints',
          complaintProvider.complaints.where((c) => c.status == 'pending').length.toString(),
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          'Total Revenue',
          '\$${_calculateTotalRevenue(propertyProvider)}',
          Icons.attach_money,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyChart(PropertyProvider propertyProvider) {
    final occupiedUnits = _calculateOccupiedUnits(propertyProvider);
    final totalUnits = _calculateTotalUnits(propertyProvider);
    final occupancyRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Occupancy Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: occupancyRate.toDouble(),
                      title: '${occupancyRate.toStringAsFixed(1)}%',
                      color: Colors.green,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: (100 - occupancyRate).toDouble(),
                      title: '',
                      color: Colors.grey[300],
                      radius: 100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(PropertyProvider propertyProvider) {
    // Sample monthly revenue data
    final monthlyRevenue = [3000.0, 3500.0, 3200.0, 3800.0, 4000.0, 4200.0];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Revenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        monthlyRevenue.length,
                        (index) => FlSpot(index.toDouble(), monthlyRevenue[index]),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsChart(ComplaintProvider complaintProvider) {
    final pendingComplaints = complaintProvider.complaints.where((c) => c.status == 'pending').length;
    final resolvedComplaints = complaintProvider.complaints.where((c) => c.status == 'resolved').length;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaints Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (pendingComplaints + resolvedComplaints).toDouble(),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: pendingComplaints.toDouble(),
                          color: Colors.orange,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: resolvedComplaints.toDouble(),
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value == 0 ? 'Pending' : 'Resolved',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(PropertyProvider propertyProvider, ComplaintProvider complaintProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),
                  title: Text('Activity ${index + 1}'),
                  subtitle: Text('Description of activity ${index + 1}'),
                  trailing: Text(
                    '${index + 1}h ago',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _calculateOccupiedUnits(PropertyProvider propertyProvider) {
    int occupied = 0;
    for (var property in propertyProvider.properties) {
      for (var floor in property.floors) {
        for (var room in floor.rooms) {
          if (room.tenantId != null && room.tenantId!.isNotEmpty) {
            occupied++;
          }
        }
      }
    }
    return occupied;
  }

  int _calculateTotalUnits(PropertyProvider propertyProvider) {
    int total = 0;
    for (var property in propertyProvider.properties) {
      for (var floor in property.floors) {
        total += floor.rooms.length;
      }
    }
    return total;
  }

  String _calculateTotalRevenue(PropertyProvider propertyProvider) {
    double total = 0;
    for (var property in propertyProvider.properties) {
      for (var floor in property.floors) {
        for (var room in floor.rooms) {
          if (room.tenantId != null && room.tenantId!.isNotEmpty) {
            total += room.rentAmount;
          }
        }
      }
    }
    return total.toStringAsFixed(2);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _InsightItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF90CAF9)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}