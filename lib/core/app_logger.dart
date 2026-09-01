import 'dart:developer' as developer;

class AppLogger {
  static const String _param = "@";

  static void info(String message, [String tag = _param]) {
    developer.log("INFO: $message", name: tag);
  }

  static void warning(String message, [String tag = _param]) {
    developer.log("WARNING: $message", name: tag);
  }

  static void error(
      String message, [
        dynamic error,
        StackTrace? stackTrace,
        String tag = _param,
      ]) {
    developer.log(
      "ERROR: $message",
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
