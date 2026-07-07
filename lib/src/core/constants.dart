import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl {
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
