import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/student/student_id_card_front.dart';
import 'package:atlasgo/src/features/student/student_provider.dart';

void main() {
  const card = StudentIdCard(
    name: 'DELA CRUZ, JUAN',
    barcode: '2024-00123',
    lrn: '123456789012',
    hasPhoto: false,
    gradeLevel: 8,
    section: 'Curie',
    schoolYear: '2026-2027',
    ocdName: 'MELBA C. PATACSIL, PhD',
    ocdPosition: 'Campus Director',
  );

  testWidgets('shows name, LRN, and OCD signature block', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StudentIdCardFront(card: card, cardWidth: 216)),
      ),
    );

    expect(find.text('DELA CRUZ, JUAN'), findsOneWidget);
    expect(find.text('123456789012'), findsOneWidget);
    expect(find.text('MELBA C. PATACSIL, PhD'), findsOneWidget);
    expect(find.text('Campus Director'), findsOneWidget);
    expect(find.text('SCHOLAR'), findsOneWidget);
  });

  testWidgets('shows an em dash for a missing LRN', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudentIdCardFront(
            card: StudentIdCard(
              name: 'DELA CRUZ, JUAN',
              hasPhoto: false,
              ocdName: 'MELBA C. PATACSIL, PhD',
              ocdPosition: 'Campus Director',
            ),
            cardWidth: 216,
          ),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
