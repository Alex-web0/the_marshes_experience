import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Singleton service for Firebase Remote Config.
///
/// Fetches `google_play_link` and `app_store_link` values from Remote Config.
/// Links are validated: must be non-null, non-empty, and start with "https".
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  /// Initialize Remote Config with defaults and fetch latest values.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set defaults
      await _remoteConfig.setDefaults({
        'google_play_link': '',
        'app_store_link': '',
      });

      // Configure fetch settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      _initialized = true;

      debugPrint('[RemoteConfig] Initialized successfully');
      debugPrint(
          '[RemoteConfig] google_play_link: "${_remoteConfig.getString('google_play_link')}"');
      debugPrint(
          '[RemoteConfig] app_store_link: "${_remoteConfig.getString('app_store_link')}"');
    } catch (e) {
      debugPrint('[RemoteConfig] Failed to initialize: $e');
      // Still mark as initialized so we don't block the app
      _initialized = true;
    }
  }

  /// Validates a link: must be non-empty and start with "https".
  bool _isValidLink(String? link) {
    if (link == null || link.isEmpty) return false;
    return link.startsWith('https');
  }

  /// Get Google Play link, or null if invalid.
  String? getGooglePlayLink() {
    final link = _remoteConfig.getString('google_play_link');
    return _isValidLink(link) ? link : null;
  }

  /// Get App Store link, or null if invalid.
  String? getAppStoreLink() {
    final link = _remoteConfig.getString('app_store_link');
    return _isValidLink(link) ? link : null;
  }

  /// Returns true if at least one valid link exists.
  bool hasValidLinks() {
    return getGooglePlayLink() != null || getAppStoreLink() != null;
  }
}
