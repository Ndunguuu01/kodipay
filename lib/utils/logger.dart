import 'package:flutter/foundation.dart';

/// A utility class for consistent logging across the application
class Logger {
  static const String _tag = 'Kodipay';

  /// Log an informational message
  static void info(String message) {
    if (kDebugMode) {
      print('$_tag [INFO] $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      print('$_tag [WARNING] $message');
    }
  }

  /// Log an error message
  static void error(String message) {
    if (kDebugMode) {
      print('$_tag [ERROR] $message');
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (kDebugMode) {
      print('$_tag [DEBUG] $message');
    }
  }

  /// Log a verbose message
  static void verbose(String message) {
    if (kDebugMode) {
      print('$_tag [VERBOSE] $message');
    }
  }

  /// Log a message with custom tag
  static void custom(String tag, String message) {
    if (kDebugMode) {
      print('$_tag [$tag] $message');
    }
  }
} 