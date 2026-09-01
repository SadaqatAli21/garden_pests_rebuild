import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../app_logger.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String _openaiApiKey = 'openai_api_key';

  Future<void> initialize() async {
    // try {
    // Set settings for Remote Config
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );

    // Set default values
    await _remoteConfig.setDefaults({
      _openaiApiKey: 'YOUR_DEFAULT_KEY_OR_EMPTY',
    });

    // Fetch and activate
    bool updated = await _remoteConfig.fetchAndActivate();
    if (updated) {
      AppLogger.info(
        "Remote Config updated and activated",
        "RemoteConfigService",
      );
    } else {
      AppLogger.info(
        "Remote Config not updated, using cached values",
        "RemoteConfigService",
      );
    }

    final key = getOpenAIApiKey();
    AppLogger.info(
        "Current OpenAI Key starts with: ${key.substring(0, min(10, key.length))}...",
        "RemoteConfigService"
    );
    // } catch (e) {
    //   AppLogger.error(
    //     "Failed to initialize Remote Config",
    //     e,
    //     null,
    //     "RemoteConfigService",
    //   );
    // }
  }

  String getOpenAIApiKey() {
    return _remoteConfig.getString(_openaiApiKey);
  }

  /// Gets all keys currently available in Remote Config
  Map<String, dynamic> getAllKeys() {
    final Map<String, dynamic> allValues = {};
    for (final key in _remoteConfig.getAll().keys) {
      allValues[key] = _remoteConfig.getValue(key).asString();
    }
    return allValues;
  }
}
