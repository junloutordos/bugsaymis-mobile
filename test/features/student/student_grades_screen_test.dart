import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/grades/grades_provider.dart';
import 'package:atlasgo/src/features/student/student_grades_screen.dart';
import 'package:atlasgo/src/shared/widgets/trend_chart.dart';

void main() {
  testWidgets('shows a quarter-over-quarter GWA trend chart on the overall tab',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentGradesProvider.overrideWith((ref) async => const GradesData(
                schoolYear: '2026-2027',
                grades: [
                  GradeEntry(
                      subjectName: 'Math',
                      q1: 2.0, q2: 1.75, q3: 1.5, q4: 1.25,
                      finalGe: 1.6, adjectival: 'Very Satisfactory', isPassed: true),
                  GradeEntry(
                      subjectName: 'Science',
                      q1: 1.5, q2: 1.5, q3: 1.5, q4: 1.5,
                      finalGe: 1.5, adjectival: 'Outstanding', isPassed: true),
                ],
              )),
        ],
        child: const MaterialApp(home: StudentGradesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The GWA trend only makes sense on the overall/"Final" tab, not on an
    // individual quarter's own subject-list tab — switch there first.
    await tester.tap(find.text('Final'));
    await tester.pumpAndSettle();

    expect(find.byType(TrendChart), findsOneWidget);
  });
}
