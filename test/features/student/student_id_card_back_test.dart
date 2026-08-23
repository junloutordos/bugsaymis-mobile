import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/student/student_id_card_back.dart';
import 'package:atlasgo/src/features/student/student_provider.dart';

void main() {
  testWidgets('shows emergency contact fields and the notice text', (tester) async {
    const card = StudentIdCard(
      name: 'DELA CRUZ, JUAN',
      barcode: '2024-00123',
      hasPhoto: false,
      ocdName: 'MELBA C. PATACSIL, PhD',
      ocdPosition: 'Campus Director',
      guardianName: 'Maria Dela Cruz',
      contactNo: '09171234567',
      address: 'Butuan City',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StudentIdCardBack(card: card, cardWidth: 216)),
      ),
    );

    expect(find.text('IN CASE OF EMERGENCY, NOTIFY'), findsOneWidget);
    expect(find.text('Maria Dela Cruz'), findsOneWidget);
    expect(find.text('09171234567'), findsOneWidget);
    expect(find.text('Butuan City'), findsOneWidget);
    expect(find.textContaining('non-transferable'), findsOneWidget);
  });

  testWidgets('shows an em dash for missing emergency fields', (tester) async {
    const card = StudentIdCard(
      name: 'DELA CRUZ, JUAN',
      hasPhoto: false,
      ocdName: 'MELBA C. PATACSIL, PhD',
      ocdPosition: 'Campus Director',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StudentIdCardBack(card: card, cardWidth: 216)),
      ),
    );

    expect(find.text('—'), findsNWidgets(3));
  });
}
