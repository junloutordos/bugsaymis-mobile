import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/core/api_client.dart';
import 'src/core/router.dart';
import 'src/core/theme.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/features/notices/notice_queue_dialog.dart';
import 'src/features/notices/notices_provider.dart';
import 'src/features/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is not configured for macOS (desktop testing only).
  // On all other platforms it initialises normally.
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: AtlasGoApp()));
}

class AtlasGoApp extends ConsumerWidget {
  const AtlasGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize FCM whenever a user transitions from unauthenticated → authenticated.
    // This covers both "app restart with existing session" and "fresh login in current session".
    ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value != null;
      final isLoggedIn = next.value != null;
      if (!wasLoggedIn && isLoggedIn) {
        ref.read(fcmServiceProvider).initialize();
      }
    });

    // Navigate to the relevant screen when a notification is tapped.
    ref.listen<Map<String, dynamic>?>(pendingNotificationProvider, (_, data) {
      if (data == null) return;
      if (data['type'] == 'student_attendance') {
        final studentId = int.tryParse(data['student_id']?.toString() ?? '');
        if (studentId != null) {
          router.go('/attendance', extra: {
            'studentId': studentId,
            'studentName': data['student_name']?.toString() ?? '',
          });
        }
      } else if (data['type'] == 'announcement') {
        // No dedicated announcement-detail screen exists yet — route to
        // whichever dashboard the current role uses, where the unread
        // queue dialog surfaces it on load.
        final user = ref.read(authStateProvider).value;
        router.go(user?.isStudent == true ? '/student/home' : '/home');
      }
      ref.read(pendingNotificationProvider.notifier).state = null;
    });

    // Emergency alert arrived while the app is foregrounded — interrupt
    // immediately via a full-screen takeover, don't wait for a tap.
    ref.listen<Map<String, dynamic>?>(pendingEmergencyAlertProvider, (_, data) {
      if (data == null) return;
      final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
      if (navigatorContext != null) {
        final item = NoticeItem(
          id: int.tryParse(data['emergency_alert_id']?.toString() ?? '') ?? 0,
          title: data['title']?.toString() ?? 'Emergency Alert',
          body: data['message']?.toString() ?? '',
          kind: 'emergency-alert',
        );
        showDialog<void>(
          context: navigatorContext,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: NoticeQueueDialog(
              item: item,
              position: '',
              showPosition: false,
              onAcknowledge: () async {
                await acknowledgeNotice(ref.read(apiClientProvider), item);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      }
      ref.read(pendingEmergencyAlertProvider.notifier).state = null;
    });

    return MaterialApp.router(
      title: 'AtlasGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      scrollBehavior: const _DragEverywhereScrollBehavior(),
    );
  }
}

/// Flutter only enables drag-scrolling for touch by default; this makes
/// lists draggable with a mouse/trackpad too (web builds, simulators).
class _DragEverywhereScrollBehavior extends MaterialScrollBehavior {
  const _DragEverywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
