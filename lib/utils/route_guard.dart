import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RouteGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.auth != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                       state.matchedLocation == '/register';

    // If not authenticated and not on auth route, redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    // If authenticated and on auth route, redirect to appropriate home
    if (isAuthenticated && isAuthRoute) {
      final role = authProvider.auth?.role;
      if (role == 'landlord') {
        return '/landlord-home';
      } else if (role == 'tenant') {
        return '/tenant-home';
      }
    }

    // No redirect needed
    return null;
  }
} 