import 'dart:io';

class AppConstants {
  static const String appName = 'AI Pest Identifire';
  static const String appTagline = 'Protect Your Plants Smartly';

  // API Key - Managed via Firebase Remote Config
  // static const String openAIApiKey = '...';
  // In production, use a backend proxy.
  static const String openAIBaseUrl =
      'https://api.openai.com/v1/chat/completions';

  // static const String openAIApiKey =
  //     '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';

  // UI Texts
  static const String scanPlant = 'Scan Plant';
  static const String savedScans = 'Saved Scans';
  static const String treatmentGuide = 'Treatment Guide';
  static const String analyzePest = 'Analyze Pest';
  static const String focusingText = 'Focus on damaged leaf area';

  // Hive/Prefs Keys
  static const String dailyScanCountKey = 'daily_scan_count';
  static const String totalScanCountKey = 'total_scan_count';
  static const String lastScanDateKey = 'last_scan_date';
  static const String aiConsentGivenKey = 'ai_consent_given';
  static const String historyAutoSaveKey = 'history_auto_save';
  static const String reminderEnabledKey = 'reminder_enabled';
  static const String reminderTimeKey = 'reminder_time';

  // Store URLs
  static const String androidStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.pests_identifier';
  static const String iosStoreUrl = 'https://apps.apple.com/app/id644...'; // Replace with actual iOS App ID
  static const String macStoreUrl = 'https://apps.apple.com/app/id644...'; // Replace with actual Mac App ID

  static String getStoreUrl() {
    if (Platform.isAndroid) return androidStoreUrl;
    if (Platform.isMacOS) return macStoreUrl;
    return iosStoreUrl;
  }
}
