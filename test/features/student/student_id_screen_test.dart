import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/student/student_id_card_back.dart';
import 'package:atlasgo/src/features/student/student_id_card_front.dart';
import 'package:atlasgo/src/features/student/student_id_screen.dart';
import 'package:atlasgo/src/features/student/student_provider.dart';

void main() {
  const card = StudentIdCard(
    name: 'DELA CRUZ, JUAN',
    barcode: '2024-00123',
    hasPhoto: false,
    ocdName: 'MELBA C. PATACSIL, PhD',
    ocdPosition: 'Campus Director',
    guardianName: 'Maria Dela Cruz',
  );

  testWidgets('shows the front face and a Show Back button by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studentIdCardProvider.overrideWith((ref) async => card)],
        child: const MaterialApp(home: StudentIdScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudentIdCardFront), findsOneWidget);
    expect(find.byType(StudentIdCardBack), findsNothing);
    expect(find.text('Show Back'), findsOneWidget);
  });

  testWidgets('tapping the flip button swaps to the back face', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studentIdCardProvider.overrideWith((ref) async => card)],
        child: const MaterialApp(home: StudentIdScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Back'));
    await tester.pumpAndSettle();

    expect(find.byType(StudentIdCardBack), findsOneWidget);
    expect(find.byType(StudentIdCardFront), findsNothing);
    expect(find.text('Show Front'), findsOneWidget);
  });
}
