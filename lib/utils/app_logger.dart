import 'package:flutter/foundation.dart';

/// Logger utility cho ứng dụng
/// Chỉ log trong debug mode, không log trong release
class AppLogger {
  const AppLogger._();

  // Log thông tin
  static void info(String message) {
    if (kReleaseMode) return;
    debugPrint('[INFO] $message');
  }

  // Log cảnh báo
  static void warn(String message) {
    if (kReleaseMode) return;
    debugPrint('[WARN] $message');
  }

  // Log lỗi
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
