import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  // Private constructor for singleton
  AnalyticsService._privateConstructor();

  // The single instance of the class
  static final AnalyticsService _instance =
  AnalyticsService._privateConstructor();

  // Factory constructor that returns the instance
  factory AnalyticsService() {
    return _instance;
  }

  // Getter for the instance (optional but sometimes preferred syntactically)
  static AnalyticsService get instance => _instance;

  FirebaseAnalytics? _analytics;

  /// Attempt to lazily initialize Analytics
  FirebaseAnalytics? get analytics {
    if (_analytics != null) return _analytics;
    try {
      _analytics = FirebaseAnalytics.instance;
      return _analytics;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseAnalytics not ready yet: $e');
      }
      return null;
    }
  }

  /// Get the FirebaseAnalyticsObserver for navigation routing
  /// Returns null if Firebase is not yet initialized.
  FirebaseAnalyticsObserver? getAnalyticsObserver() {
    final a = analytics;
    if (a != null) {
      return FirebaseAnalyticsObserver(analytics: a);
    }
    return null;
  }

  /// Log a custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Analytics events only support alphanumeric and underscore, up to 40 chars
    // Format the name slightly to ensure it is valid
    final formattedName = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .take(40);

    if (kDebugMode) {
      debugPrint('AnalyticsEvent logged: $formattedName');
      if (parameters != null) {
        debugPrint('  Parameters: $parameters');
      }
    }

    try {
      await analytics?.logEvent(name: formattedName, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error logging analytics event: $e');
      }
    }
  }
}

// Extension to cleanly limit string length for analytics event names limitations
extension StringExtension on String {
  String take(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
