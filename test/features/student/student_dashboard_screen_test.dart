import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:atlasgo/src/core/theme.dart';
import 'package:atlasgo/src/features/auth/auth_provider.dart';
import 'package:atlasgo/src/features/grades/grades_provider.dart';
import 'package:atlasgo/src/features/portal/portal_provider.dart';
import 'package:atlasgo/src/features/student/student_dashboard_screen.dart';
import 'package:atlasgo/src/features/student/student_provider.dart';
import 'package:atlasgo/src/shared/widgets/hero_header.dart';
import 'package:atlasgo/src/shared/widgets/radial_progress_ring.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: 2,
        name: 'Juan Dela Cruz',
        email: 'juan@crc.pshs.edu.ph',
        role: 'student',
      );
}

void main() {
  testWidgets('shows a HeroHeader with an attendance status badge, no AppHeader', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          studentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 2,
                name: 'Juan Dela Cruz',
                gradeLevel: 8,
                section: 'Curie',
                schoolYear: '2026-2027',
              )),
          studentTodayProvider.overrideWith((ref) async =>
              const StudentTodaySummary(lastStatus: 'in', totalScans: 1)),
          studentGradesProvider.overrideWith((ref) async => const GradesData(grades: [])),
          portalDashboardProvider.overrideWith((ref) async => const PortalDashboard(
                gradeLevel: 8,
                completion: [],
                totalDone: 0,
                total: 0,
                clearance: null,
                intern: null,
              )),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.byType(AppHeader), findsNothing);
    expect(find.byType(StatusBadge), findsOneWidget);
  });

  testWidgets('shows a RadialProgressRing for GWA instead of the text badge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          studentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 2,
                name: 'Juan Dela Cruz',
                gradeLevel: 8,
                section: 'Curie',
                schoolYear: '2026-2027',
              )),
          studentTodayProvider.overrideWith((ref) async =>
              const StudentTodaySummary(lastStatus: 'in', totalScans: 1)),
          studentGradesProvider.overrideWith((ref) async => const GradesData(grades: [
                GradeEntry(subjectName: 'Math', q1: 1.5, q2: 1.5, q3: 1.5, q4: 1.5, finalGe: 1.5, adjectival: 'Outstanding', isPassed: true),
              ])),
          portalDashboardProvider.overrideWith((ref) async => const PortalDashboard(
                gradeLevel: 8,
                completion: [],
                totalDone: 0,
                total: 0,
                clearance: null,
                intern: null,
              )),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadialProgressRing), findsWidgets);
    expect(find.textContaining('GWA'), findsNothing);
  });

  testWidgets('shows a completion RadialProgressRing on the annual-forms todo row',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          studentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 2, name: 'Juan Dela Cruz', gradeLevel: 8, section: 'Curie', schoolYear: '2026-2027')),
          studentTodayProvider.overrideWith((ref) async =>
              const StudentTodaySummary(lastStatus: 'in', totalScans: 1)),
          studentGradesProvider.overrideWith((ref) async => const GradesData(grades: [])),
          portalDashboardProvider.overrideWith((ref) async => const PortalDashboard(
                gradeLevel: 8,
                completion: [],
                totalDone: 3,
                total: 10,
                clearance: null,
                intern: null,
              )),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Annual forms'), findsOneWidget);
    expect(find.byType(RadialProgressRing), findsWidgets);
  });

  testWidgets('shows grade/section and school year inside the hero, with no separate identity card',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          studentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 2, name: 'Juan Dela Cruz', gradeLevel: 8, section: 'Curie', schoolYear: '2026-2027')),
          studentTodayProvider.overrideWith((ref) async =>
              const StudentTodaySummary(lastStatus: 'in', totalScans: 1)),
          studentGradesProvider.overrideWith((ref) async => const GradesData(grades: [])),
          portalDashboardProvider.overrideWith((ref) async => const PortalDashboard(
                gradeLevel: 8,
                completion: [],
                totalDone: 0,
                total: 0,
                clearance: null,
                intern: null,
              )),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Exactly one HeroHeader (already asserted elsewhere), and the
    // grade/section + school year now live inside it instead of a
    // separate card.
    expect(find.textContaining('Grade 8'), findsOneWidget);
    expect(find.textContaining('Curie'), findsOneWidget);
    expect(find.textContaining('2026-2027'), findsOneWidget);
    // "Student" role badge and the separate navy identity card are gone —
    // there is now only one gradient-decorated Container using the hero
    // gradient (the HeroHeader itself).
    expect(find.text('Student'), findsNothing);
  });

  testWidgets('tapping the hero navigates to profile', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const StudentDashboardScreen()),
      GoRoute(path: '/profile', builder: (c, s) => const Scaffold(body: Text('Profile Page'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          studentProfileProvider.overrideWith((ref) async => const StudentProfile(
                id: 2, name: 'Juan Dela Cruz', gradeLevel: 8, section: 'Curie', schoolYear: '2026-2027')),
          studentTodayProvider.overrideWith((ref) async =>
              const StudentTodaySummary(lastStatus: 'in', totalScans: 1)),
          studentGradesProvider.overrideWith((ref) async => const GradesData(grades: [])),
          portalDashboardProvider.overrideWith((ref) async => const PortalDashboard(
                gradeLevel: 8,
                completion: [],
                totalDone: 0,
                total: 0,
                clearance: null,
                intern: null,
              )),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Juan'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Page'), findsOneWidget);
  });
}
