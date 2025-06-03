import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/tenant_home_screen.dart';
import 'screens/landlord_home_screen.dart';
import 'screens/password_reset_request_screen.dart';
import 'screens/password_reset_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => const LoginScreen(),
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
      path: '/tenant-home',
      builder: (context, state) => const TenantHomeScreen(),
    ),
    GoRoute(
      path: '/landlord-home',
      builder: (context, state) => const LandlordHomeScreen(),
    ),
    GoRoute(
      path: '/request-password-reset',
      builder: (context, state) => const PasswordResetRequestScreen(),
    ),
    GoRoute(
      path: '/reset-password/:resetToken',
      builder: (context, state) {
        final resetToken = state.pathParameters['resetToken']!;
        return PasswordResetScreen(resetToken: resetToken);
      },
    ),
  ],
);
