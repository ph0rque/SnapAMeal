import 'package:flutter/foundation.dart';

/// Simple logger with three levels.
class Logger {
  Logger._();

  static void d(String message) => _log('DEBUG', message);
  static void i(String message) => _log('INFO', message);
  static void e(String message) => _log('ERROR', message);

  static void _log(String level, String message) {
    final ts = DateTime.now().toIso8601String();
    if (kDebugMode) {
      print('[$level] $ts — $message');
    }
  }
}
