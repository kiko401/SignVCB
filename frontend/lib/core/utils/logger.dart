import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void d(Object? message) {
    if (kDebugMode) debugPrint('🐛 $message');
  }

  static void i(Object? message) {
    debugPrint('ℹ️ $message');
  }

  static void w(Object? message) {
    debugPrint('⚠️ $message');
  }

  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ $message');
    if (error != null) debugPrint('   error: $error');
    if (stackTrace != null) debugPrint('   stack: $stackTrace');
  }
}
