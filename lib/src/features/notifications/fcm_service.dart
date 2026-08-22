import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart before this runs
}

/// Set by the FCM service when the user taps a notification.
/// main.dart listens to this and navigates to the appropriate screen.
final pendingNotificationProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Set the instant an emergency-alert push arrives in the foreground —
/// unlike pendingNotificationProvider (which only fires on a notification
/// tap), this must interrupt immediately, matching the web takeover's
/// real-time behavior. AtlasGo has no persistent socket connection, so
/// this push IS the mobile real-time channel.
final pendingEmergencyAlertProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.read(apiClientProvider), ref);
});

class FcmService {
  final ApiClient _api;
  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'attendance_channel',
    'Gate Attendance',
    description: 'Notifications when your child enters or leaves school',
    importance: Importance.high,
  );

  FcmService(this._api, this._ref);

  Future<void> initialize() async {
    // Firebase is not configured for macOS — skip FCM on desktop.
    if (defaultTargetPlatform == TargetPlatform.macOS) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'emergency_alert') {
        _ref.read(pendingEmergencyAlertProvider.notifier).state = message.data;
        return; // the takeover overlay handles this — no local notification needed
      }

      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });

    // App in background — user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _ref.read(pendingNotificationProvider.notifier).state = message.data;
    });

    // App was killed — opened via notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _ref.read(pendingNotificationProvider.notifier).state =
          initialMessage.data;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _registerToken();
    _messaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _api.put('/fcm-token', data: {'fcm_token': token});
    } catch (_) {
      // Best-effort — don't crash the app on token registration failure
    }
  }
}
