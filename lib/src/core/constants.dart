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
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String parentContactKey = 'parent_contact_id';
}
