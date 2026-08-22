import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
