import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/tenant_home_screen.dart';
import 'screens/landlord_home_screen.dart';
import 'screens/password_reset_request_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/property_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/direct_message_screen.dart';
import 'screens/direct_message_error_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/property_list_screen.dart';
import 'screens/add_property_screen.dart';
import 'screens/tenant_list_screen.dart';
import 'screens/messaging_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/RoomDetailScreen.dart';
import 'screens/tenant_details_screen.dart';
import 'screens/add_tenant_enhanced_screen.dart';
import 'screens/complaints_screen.dart';
import 'screens/add_complaint_screen.dart';

import 'providers/auth_provider.dart';
import 'package:kodipay/utils/logger.dart';
import 'package:kodipay/models/property_model.dart';

import 'widgets/bottom_nav_shell.dart';

// Track the last redirect time to prevent redirect loops
DateTime? _lastRedirectTime;
const redirectCooldown = Duration(milliseconds: 500); // Shorter cooldown to prevent excessive delays

// Track the last location to prevent redirecting to the same location repeatedly
String? _lastRedirectLocation;

// Track if we're currently in the process of redirecting
bool _isRedirecting = false;

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    errorBuilder: (context, state) => const LoginScreen(),

    redirect: (context, state) async {
      final location = state.uri.toString();
      print('Router.redirect: Evaluating redirect for location: $location'); // Debug log
      
      // If we're already in the process of redirecting, skip this redirect
      if (_isRedirecting) {
        print('Router.redirect: Already redirecting, skipping');
        return null;
      }
      
      // Implement redirect debounce to prevent loops
      final now = DateTime.now();
      if (_lastRedirectTime != null) {
        final timeSinceLastRedirect = now.difference(_lastRedirectTime!);
        if (timeSinceLastRedirect < redirectCooldown) {
          print('Router.redirect: Skipping redirect, too soon after previous redirect (${timeSinceLastRedirect.inMilliseconds}ms)');
          return null; // Skip redirect if it's too soon after the last one
        }
      }
      
      // Prevent redirecting to the same location repeatedly
      if (_lastRedirectLocation == location) {
        print('Router.redirect: Already at location $location, skipping redirect');
        return null;
      }
      
      // Wait for auth initialization to complete before checking auth state
      if (authProvider.isLoading) {
        print('Router.redirect: AuthProvider is initializing, waiting...'); // Debug log
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        // Re-check after a short delay
        if (authProvider.isLoading) {
          print('Router.redirect: Still initializing, returning null'); // Debug log
          return null; // Don't redirect while initializing
        }
      }
      
      print('Router.redirect: Checking auth state'); // Debug log
      final isLoggedIn = authProvider.auth != null;
      print('Router.redirect: isLoggedIn = $isLoggedIn'); // Debug log

      Logger.info('Router Redirect: Navigating to $location');
      Logger.info('Router Redirect: User logged in: $isLoggedIn');
      
      // Additional debug info about auth state
      if (authProvider.auth != null) {
        print('Router.redirect: Auth user ID: ${authProvider.auth!.id}, Name: ${authProvider.auth!.name}'); // Debug log
      } else {
        print('Router.redirect: No auth user'); // Debug log
      }

      const publicRoutes = [
        '/login',
        '/register',
        '/request-password-reset',
        '/reset-password',
      ];

      final isPublicRoute = publicRoutes.any((route) => location.startsWith(route));
      print('Router.redirect: isPublicRoute = $isPublicRoute'); // Debug log

      // If not logged in, always go to login (do not restore previous route)
      if (!isLoggedIn) {
        // Only if we're not already on a public route
        if (!isPublicRoute) {
          Logger.warning('Redirecting to login: Not authenticated');
          authProvider.clearIntendedDestination();
          
          // Store the current location for redirect tracking
          _lastRedirectTime = DateTime.now();
          _lastRedirectLocation = '/login';
          _isRedirecting = true;
          print('Router.redirect: Redirecting to /login'); // Debug log
          
          // Reset the redirecting flag after a short delay
          Future.delayed(redirectCooldown, () {
            _isRedirecting = false;
          });
          
          return '/login';
        }
        print('Router.redirect: Already on public route, no redirect needed'); // Debug log
        return null; // Already on a public route, no need to redirect
      }

      if (isLoggedIn && isPublicRoute) {
        final displayRole = authProvider.auth?.displayRole;
        final role = authProvider.auth?.role;
        print('DEBUG: Router redirect - role: $role, displayRole: $displayRole');
        final intendedDestination = authProvider.intendedDestination;
        Logger.info('Redirecting logged in user to home or intended destination');

        if (intendedDestination != null) {
          authProvider.clearIntendedDestination();
          
          // Store the current location for redirect tracking
          _lastRedirectTime = DateTime.now();
          _lastRedirectLocation = intendedDestination;
          _isRedirecting = true;
          print('Router.redirect: Redirecting to intended destination: $intendedDestination'); // Debug log
          
          // Reset the redirecting flag after a short delay
          Future.delayed(redirectCooldown, () {
            _isRedirecting = false;
          });
          
          return intendedDestination;
        }

        final homeRoute = displayRole == 'landlord' ? '/landlord-home' : '/tenant-home';
        
        // Store the current location for redirect tracking
        _lastRedirectTime = DateTime.now();
        _lastRedirectLocation = homeRoute;
        _isRedirecting = true;
        print('Router.redirect: Redirecting to home route: $homeRoute'); // Debug log
        
        // Reset the redirecting flag after a short delay
        Future.delayed(redirectCooldown, () {
          _isRedirecting = false;
        });
        
        return homeRoute;
      }

      print('Router.redirect: No redirect needed'); // Debug log
      return null; // No redirect needed
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/request-password-reset',
        builder: (context, state) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: '/reset-password/:resetToken',
        builder: (context, state) {
          final token = state.pathParameters['resetToken']!;
          return PasswordResetScreen(resetToken: token);
        },
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/update-profile',
        builder: (context, state) => const UpdateProfileScreen(),
      ),

      // Landlord Shell & Routes
      ShellRoute(
        builder: (context, state, child) {
          final displayRole = authProvider.auth?.displayRole ?? '';
          if (displayRole == 'landlord') {
            return BottomNavShell(child: child);
          } else {
            return Scaffold(body: child); // No bottom nav for non-landlord
          }
        },
        routes: [
          GoRoute(
            path: '/landlord-home',
            builder: (context, state) => const LandlordHomeScreen(),
            routes: [
              GoRoute(
                path: 'properties',
                builder: (context, state) => const PropertyListScreen(),
              ),
              GoRoute(
                path: 'properties/add',
                builder: (context, state) => const AddPropertyScreen(),
              ),
              GoRoute(
                path: 'tenants',
                builder: (context, state) => const TenantListScreen(),
              ),
              GoRoute(
                path: 'tenants/add',
                builder: (context, state) {
                  final params = Uri.parse(state.uri.toString()).queryParameters;
                  final propertyId = params['propertyId'] ?? '';
                  final roomId = params['roomId'] ?? '';
                  final floorNumber = int.tryParse(params['floorNumber'] ?? '') ?? 0;
                  final roomNumber = params['roomNumber'] ?? '';

                  // Try to get property from extra, otherwise fetch from provider
                  PropertyModel? property;
                  List<String> excludeTenantIds = [];

                  if (state.extra != null) {
                    if (state.extra is PropertyModel) {
                      property = state.extra as PropertyModel;
                    } else if (state.extra is Map<String, dynamic>) {
                      final extraData = state.extra as Map<String, dynamic>;
                      property = extraData['property'] as PropertyModel?;
                      excludeTenantIds = (extraData['excludeTenantIds'] as List<dynamic>?)?.cast<String>() ?? [];
                    }
                  }

                  // If no property provided and no propertyId in params, we'll let the user select
                  if (property == null && propertyId.isEmpty) {
                    return AddTenantEnhancedScreen(
                      propertyId: '',
                      roomId: '',
                      floorNumber: 0,
                      roomNumber: '',
                      property: PropertyModel(
                        id: '',
                        name: '',
                        address: '',
                        rentAmount: 0,
                        totalRooms: 0,
                        floors: [],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      excludeTenantIds: excludeTenantIds,
                    );
                  }

                  // If no property provided but propertyId exists, create a default one
                  property ??= PropertyModel(
                    id: propertyId,
                    name: 'Property',
                    address: '',
                    rentAmount: 0,
                    totalRooms: 0,
                    floors: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  return AddTenantEnhancedScreen(
                    propertyId: propertyId,
                    roomId: roomId,
                    floorNumber: floorNumber,
                    roomNumber: roomNumber,
                    property: property,
                    excludeTenantIds: excludeTenantIds,
                  );
                },
              ),
              GoRoute(
                path: 'complaints',
                builder: (context, state) => const ComplaintsScreen(),
              ),
              GoRoute(
                path: 'add-complaint',
                builder: (context, state) => const AddComplaintScreen(),
              ),
              GoRoute(
                path: 'messages',
                builder: (context, state) => const MessagingDashboardScreen(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Tenant Shell & Routes
      ShellRoute(
        builder: (context, state, child) {
          final displayRole = authProvider.auth?.displayRole ?? '';
          if (displayRole == 'tenant') {
            return BottomNavShell(child: child);
          } else {
            return Scaffold(body: child); // No bottom nav for non-tenant
          }
        },
        routes: [
          GoRoute(
            path: '/tenant-home',
            builder: (context, state) => const TenantHomeScreen(),
            // Add tenant-specific nested routes here if needed
          ),
        ],
      ),

      // Property route
      GoRoute(
        path: '/property/:propertyId',
        builder: (context, state) {
          final id = state.pathParameters['propertyId']!;
          return PropertyScreen(propertyId: id);
        },
      ),

      // Room detail route
      GoRoute(
        path: '/room-detail',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final room = data['room'] as dynamic;
          final propertyId = data['propertyId'] as String;
          final tenant = data['tenant'] as dynamic;
          return RoomDetailScreen(
            room: room,
            propertyId: propertyId,
            tenant: tenant,
          );
        },
      ),

      // Tenant detail route
      GoRoute(
        path: '/tenant-details',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final tenantId = data['tenantId'] as String;
          final propertyId = data['propertyId'] as String;
          return TenantDetailsScreen(
            tenantId: tenantId,
            propertyId: propertyId,
          );
        },
      ),

      // Messaging Routes
      GoRoute(
        path: '/messaging/group/:propertyId',
        builder: (context, state) {
          final id = state.pathParameters['propertyId']!;
          return GroupChatScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/messaging/direct/:recipientId/:recipientPhoneNumber',
        builder: (context, state) {
          final id = state.pathParameters['recipientId']!;
          final phone = state.pathParameters['recipientPhoneNumber']!;
          return DirectMessageScreen(recipientId: id, recipientPhoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/messaging/direct/:recipientId',
        builder: (context, state) {
          final id = state.pathParameters['recipientId']!;
          return DirectMessageErrorScreen(recipientId: id);
        },
      ),
    ],
  );
}
