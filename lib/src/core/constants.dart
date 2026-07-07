import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  /// Production API endpoint (Cloudflare-proxied ALB).
  static const String _prodBaseUrl = 'https://mis.crc.pshs.edu.ph/api/mobile';

  /// Compile-time override: flutter build --dart-define=API_BASE_URL=…
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

    // Release builds always talk to production.
    if (kReleaseMode) return _prodBaseUrl;

    // Debug/profile builds default to the local Docker backend.
    if (kIsWeb) {
      // Web (Chrome dev) hits the backend directly on localhost
      return 'http://localhost:8080/api/mobile';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator reaches host machine via 10.0.2.2
        return 'http://10.0.2.2:8080/api/mobile';
      default:
        // iOS device/simulator and macOS use localhost
        return 'http://localhost:8080/api/mobile';
    }
  }

  static const String appName = 'AtlasGo';

  /// Firebase web client ID — audience for Google ID tokens the backend
  /// verifies (google_sign_in serverClientId). Public, not a secret.
  static const String googleServerClientId =
      '54745889381-7cn2j3rr588ba5o2fl7fte8gpjl52hmm.apps.googleusercontent.com';

  /// Students must sign in with their official school Google account.
  static const String googleHostedDomain = 'crc.pshs.edu.ph';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String parentContactKey = 'parent_contact_id';
}
