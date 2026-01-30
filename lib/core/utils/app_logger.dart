import 'dart:developer' as developer;

/// Simple logger for the application
class AppLogger {
  /// Log debug message
  static void debug(String message, {String? tag}) {
    _log('DEBUG', message, tag);
  }

  /// Log info message
  static void info(String message, {String? tag}) {
    _log('INFO', message, tag);
  }

  /// Log warning message
  static void warning(String message, {String? tag}) {
    _log('WARNING', message, tag);
  }

  /// Log error message
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, null);
    if (error != null) {
      developer.log(
        'Error: $error',
        name: 'RoamQuest',
        time: DateTime.now(),
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _log(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    developer.log('$timestamp $level $tagStr$message');
  }
}
