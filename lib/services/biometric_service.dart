import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logger.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      Logger.error('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) {
      return [];
    }
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      Logger.error('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        Logger.error('Biometrics not available');
      } else if (e.code == auth_error.notEnrolled) {
        Logger.error('No biometrics enrolled');
      } else {
        Logger.error('Error during authentication: $e');
      }
      return false;
    }
  }
} 