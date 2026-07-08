import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/student_link_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/children/children_screen.dart';
import '../features/children/link_child_screen.dart';
import '../features/grades/grades_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notification_preferences_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/portal/clearance_screen.dart';
import '../features/portal/forms_overview_screen.dart';
import '../features/portal/leave_passes_screen.dart';
import '../features/portal/lost_found_screen.dart';
import '../features/portal/medical_section_form_screen.dart';
import '../features/portal/profile_section_form_screen.dart';
import '../features/portal/rh_application_screen.dart';
import '../features/portal/services_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/student/student_dashboard_screen.dart';
import '../features/student/student_grades_screen.dart';
import '../features/student/student_schedule_screen.dart';
import '../features/student/student_attendance_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user     = authState.value;
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isLoggedIn   = user != null;
      final publicPaths  = {'/login', '/register', '/student/link', '/verify-email'};
      final isPublic     = publicPaths.contains(state.matchedLocation);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn  && isPublic)  {
        return user.isStudent ? '/student/home' : '/home';
      }

      // Prevent students from accessing parent routes and vice versa
      if (isLoggedIn && user.isStudent) {
        final parentOnlyPrefixes = ['/home', '/attendance', '/grades', '/schedule', '/children'];
        final onParentRoute = parentOnlyPrefixes.any(
          (p) => state.matchedLocation == p || state.matchedLocation.startsWith('$p/'),
        );
        if (onParentRoute) return '/student/home';
      }

      if (isLoggedIn && user.isParent) {
        final studentOnlyPrefix = '/student/';
        if (state.matchedLocation.startsWith(studentOnlyPrefix)) return '/home';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(path: '/login',    builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, st) => const RegisterScreen()),
      GoRoute(
        path: '/student/link',
        builder: (ctx, st) {
          final extra = st.extra as Map<String, dynamic>?;
          return StudentLinkScreen(
            idToken: extra?['idToken'] as String? ?? '',
            email: extra?['email'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (ctx, st) {
          final extra = st.extra as Map<String, dynamic>?;
          return VerifyEmailScreen(email: extra?['email'] as String? ?? '');
        },
      ),

      // ── Parent routes ──────────────────────────────────────────────────
      GoRoute(path: '/home',     builder: (ctx, st) => const HomeScreen()),
      GoRoute(path: '/grades',   builder: (ctx, st) => const GradesScreen()),
      GoRoute(path: '/schedule', builder: (ctx, st) => const ScheduleScreen()),
      GoRoute(
        path: '/attendance',
        builder: (ctx, st) {
          final extra = st.extra as Map<String, dynamic>?;
          return AttendanceScreen(
            studentId: extra?['studentId'] as int?,
            studentName: extra?['studentName'] as String?,
          );
        },
      ),
      GoRoute(path: '/children',       builder: (ctx, st) => const ChildrenScreen()),
      GoRoute(path: '/children/link',  builder: (ctx, st) => const LinkChildScreen()),
      GoRoute(path: '/notification-preferences', builder: (ctx, st) => const NotificationPreferencesScreen()),
      GoRoute(path: '/profile',        builder: (ctx, st) => const ProfileScreen()),

      // ── Student routes ─────────────────────────────────────────────────
      GoRoute(path: '/student/home',       builder: (ctx, st) => const StudentDashboardScreen()),
      GoRoute(path: '/student/grades',     builder: (ctx, st) => const StudentGradesScreen()),
      GoRoute(path: '/student/schedule',   builder: (ctx, st) => const StudentScheduleScreen()),
      GoRoute(path: '/student/attendance', builder: (ctx, st) => const StudentAttendanceScreen()),
      GoRoute(path: '/student/services',   builder: (ctx, st) => const ServicesScreen()),

      // ── Student portal (forms, RH, clearance) ──────────────────────────
      GoRoute(path: '/student/portal/forms', builder: (ctx, st) => const FormsOverviewScreen()),
      GoRoute(
        path: '/student/portal/forms/profile/:section',
        builder: (ctx, st) =>
            ProfileSectionFormScreen(section: st.pathParameters['section']!),
      ),
      GoRoute(
        path: '/student/portal/forms/medical/:section',
        builder: (ctx, st) =>
            MedicalSectionFormScreen(section: st.pathParameters['section']!),
      ),
      GoRoute(path: '/student/portal/rh-application', builder: (ctx, st) => const RhApplicationScreen()),
      GoRoute(path: '/student/portal/leave-passes',   builder: (ctx, st) => const LeavePassesScreen()),
      GoRoute(path: '/student/portal/clearance',      builder: (ctx, st) => const ClearanceScreen()),
      GoRoute(path: '/student/portal/lost-found',     builder: (ctx, st) => const LostFoundScreen()),
    ],
  );
});
