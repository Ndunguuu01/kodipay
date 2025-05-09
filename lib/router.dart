import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/screens/PropertyListScreen.dart';
import 'package:kodipay/screens/add_property_screen.dart';
import 'package:kodipay/screens/add_tenant_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/tenant_home_screen.dart';
import 'screens/landlord_home_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/add_complaint_screen.dart';
import 'screens/property_screen.dart';
import 'screens/paid_houses_screen.dart';
import 'screens/unpaid_houses_screen.dart';
import 'screens/general_invoice_screen.dart';
import 'screens/payment_screen.dart' as payment_screen;
import 'screens/bills_screen.dart';
import 'screens/receipts_screen_new.dart' as receipts_screen;
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/messaging_dashboard_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/direct_message_screen.dart';
import 'screens/leases_screen.dart'; 
import 'screens/landlord_complaints_screen.dart'; 
import 'screens/landlord_bills_screen.dart';
import 'providers/auth_provider.dart';

GoRouter router(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.auth != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        if (authProvider.auth?.role == 'tenant') {
          return '/tenant-home';
        } else if (authProvider.auth?.role == 'landlord') {
          return '/landlord-home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final auth = authProvider.auth;
          if (auth == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/login');
            });
            return const SizedBox.shrink();
          } else if (auth.role == 'tenant') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/tenant-home');
            });
            return const SizedBox.shrink();
          } else if (auth.role == 'landlord') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/landlord-home');
            });
            return const SizedBox.shrink();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/login');
            });
            return const SizedBox.shrink();
          }
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/tenant-home',
        builder: (context, state) => const TenantHomeScreen(),
        routes: [
          GoRoute(
            path: 'complaints',
            builder: (context, state) => const ComplaintsScreen(),
          ),
          GoRoute(
            path: 'add-complaint',
            builder: (context, state) => const AddComplaintScreen(),
          ),
          GoRoute(
            path: 'payment',
            builder: (context, state) => const payment_screen.PaymentScreen(),
          ),
          GoRoute(
            path: 'bills',
            builder: (context, state) => const TenantBillsScreen(),
          ),
          GoRoute(
            path: 'receipts',
            builder: (context, state) => const receipts_screen.ReceiptsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'leases',
            builder: (context, state) => const LeasesScreen(),
          ),
          GoRoute(
            path: 'messaging',
            builder: (context, state) => const MessagingDashboardScreen(),
            routes: [
              GoRoute(
                path: 'group/:propertyId',
                builder: (context, state) => GroupChatScreen(
                  propertyId: state.pathParameters['propertyId']!,
                ),
              ),
              GoRoute(
                path: 'direct/:recipientId/:recipientPhoneNumber',
                builder: (context, state) => DirectMessageScreen(
                  recipientId: state.pathParameters['recipientId']!,
                  recipientPhoneNumber: state.pathParameters['recipientPhoneNumber']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/landlord-home',
        builder: (context, state) => const LandlordHomeScreen(),
        routes: [
          GoRoute(
            path: 'properties',
            builder: (context, state) => const PropertyListScreen(),
            routes: [
              GoRoute(
                path: 'paid-houses',
                builder: (context, state) => const PaidHousesScreen(),
              ),
              GoRoute(
                 path: 'add-property',
                 builder: (context, state) => AddPropertyScreen(),
              ),
              GoRoute(
              path: 'property-details/:propertyId',
              builder: (context, state) {
                final propertyId = state.pathParameters['propertyId']!;
                return PropertyScreen(propertyId: propertyId); 
              },
            ),
              GoRoute(
                path: 'unpaid-houses',
                builder: (context, state) => const UnpaidHousesScreen(),
              ),
              GoRoute(
                path: 'general-invoice',
                builder: (context, state) => const GeneralInvoiceScreen(),
              ),
              GoRoute(
                path: 'add-tenant',
                builder: (context, state) {
                  final args = state.extra as Map<String, dynamic>;
                  return AddTenantScreen(
                    propertyId: args['propertyId'],
                    roomId: args['roomId'],
                    excludeTenantIds: args['excludeTenantIds'] ?? [],
                  );
                },
              ),
              GoRoute(
                path: ':propertyId',
                builder: (context, state) {
                  final propertyId = state.pathParameters['propertyId']!;
                  return PropertyScreen(propertyId: propertyId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'complaints',
            builder: (context, state) => const LandlordComplaintsScreen(),
          ),
          GoRoute(
            path: 'bills',
            builder: (context, state) => const LandlordBillsScreen(),
          ),
          GoRoute(
            path: 'messaging',
            builder: (context, state) => const MessagingDashboardScreen(),
            routes: [
              GoRoute(
                path: 'group/:propertyId',
                builder: (context, state) => GroupChatScreen(
                  propertyId: state.pathParameters['propertyId']!,
                ),
              ),
              GoRoute(
                path: 'direct/:recipientId/:recipientPhoneNumber',
                builder: (context, state) => DirectMessageScreen(
                  recipientId: state.pathParameters['recipientId']!,
                  recipientPhoneNumber: state.pathParameters['recipientPhoneNumber']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/messaging/direct/:recipientId/:recipientPhoneNumber',
        builder: (context, state) => DirectMessageScreen(
          recipientId: state.pathParameters['recipientId']!,
          recipientPhoneNumber: state.pathParameters['recipientPhoneNumber']!,
        ),
      ),
      GoRoute(
        path: '/messaging/group/:propertyId',
        builder: (context, state) => GroupChatScreen(
          propertyId: state.pathParameters['propertyId']!,
        ),
      ),
    ],
    refreshListenable: authProvider,
  );
}

