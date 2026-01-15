import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    if (kReleaseMode) return;
    debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    if (kReleaseMode) return;
    debugPrint('[WARN] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('  $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
