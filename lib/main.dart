import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/core/router.dart';
import 'src/core/theme.dart';
import 'src/features/auth/auth_provider.dart';
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
          router.push('/attendance', extra: {
            'studentId': studentId,
            'studentName': data['student_name']?.toString() ?? '',
          });
        }
      }
      ref.read(pendingNotificationProvider.notifier).state = null;
    });

    return MaterialApp.router(
      title: 'AtlasGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
