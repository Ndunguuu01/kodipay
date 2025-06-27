
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

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    errorBuilder: (context, state) => const LoginScreen(),

    redirect: (context, state) {
      final isLoggedIn = authProvider.auth != null;
      final location = state.uri.toString();

      Logger.info('Router Redirect: Navigating to $location');
      Logger.info('Router Redirect: User logged in: $isLoggedIn');

      const publicRoutes = [
        '/login',
        '/register',
        '/request-password-reset',
        '/reset-password',
      ];

      final isPublicRoute = publicRoutes.any((route) => location.startsWith(route));

      if (!isLoggedIn && !isPublicRoute) {
        Logger.warning('Redirecting to login: Not authenticated');
        // Store the intended destination
        authProvider.setIntendedDestination(location);
        return '/login';
      }

      if (isLoggedIn && isPublicRoute) {
        final role = authProvider.auth?.role;
        final intendedDestination = authProvider.intendedDestination;
        Logger.info('Redirecting logged in user to home or intended destination');

        if (intendedDestination != null) {
          authProvider.clearIntendedDestination();
          return intendedDestination;
        }

        return role == 'landlord' ? '/landlord-home' : '/tenant-home';
      }

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
        builder: (context, state, child) => BottomNavShell(child: child),
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
          GoRoute(
            path: '/tenant-home',
            builder: (context, state) => const TenantHomeScreen(),
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
