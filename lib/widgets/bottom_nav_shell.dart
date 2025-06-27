import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatefulWidget {
  final Widget child;

  const BottomNavShell({Key? key, required this.child}) : super(key: key);

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  static const List<String> _routePaths = [
    '/landlord-home',
    '/landlord-home/tenants',
    '/landlord-home/messages',
    '/landlord-home/complaints',
    '/landlord-home/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    final String location = router.routerDelegate.currentConfiguration.uri.toString() ?? '';
    print('BottomNavShell: current location in _calculateSelectedIndex: $location');
    // Find the longest matching path
    int selectedIndex = 0;
    int maxMatchLength = 0;
    for (int i = 0; i < _routePaths.length; i++) {
      if (location.startsWith(_routePaths[i]) && _routePaths[i].length > maxMatchLength) {
        selectedIndex = i;
        maxMatchLength = _routePaths[i].length;
      }
    }
    print('BottomNavShell: calculated selectedIndex: $selectedIndex');
    return selectedIndex;
  }

  void _onItemTapped(int index) {
    if (index < 0 || index >= _routePaths.length) return;
    final String target = _routePaths[index];
    print('BottomNavShell: tapped index: \$index, target route: \$target');
    final GoRouter router = GoRouter.of(context);
    final String location = router.routerDelegate.currentConfiguration.uri.toString() ?? '';
    print('BottomNavShell: current location: $location');
    if (target != location) {
      router.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard, color: selectedIndex == 0 ? Colors.black : Colors.grey),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people, color: selectedIndex == 1 ? Colors.black : Colors.grey),
            label: 'Tenants',
          ),
          NavigationDestination(
            icon: Icon(Icons.message, color: selectedIndex == 2 ? Colors.black : Colors.grey),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning, color: selectedIndex == 3 ? Colors.black : Colors.grey),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: selectedIndex == 4 ? Colors.black : Colors.grey),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
