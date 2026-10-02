import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/admission_slips/admission_slips_provider.dart';
import 'package:atlasgo/src/features/admission_slips/admission_slips_screen.dart';

AdmissionSlipsData _data() => const AdmissionSlipsData(
      needsSlip: [
        SlipItem(itemKey: 'homeroom:5', date: '2026-08-12', label: 'Absence', subjects: ['Filipino']),
        SlipItem(itemKey: 'homeroom:6', date: '2026-08-13', label: 'Tardy', subjects: [], requestStatus: 'pending'),
      ],
      requests: [
        SlipRequest(
            id: 3,
            status: 'rejected',
            reason: 'Fever',
            hasDocument: false,
            decisionNote: 'Attach certificate',
            items: [SlipRequestItem(date: '2026-08-12', label: 'Absence')],
            slipIds: []),
      ],
      slips: [
        IssuedSlip(id: 7, infractionDate: '2026-08-01', label: 'Tardy', excusedStatus: 'excused', hasDocument: false),
      ],
      badge: 1,
    );

Widget _app(AdmissionSlipsData data) => ProviderScope(
      overrides: [admissionSlipsProvider.overrideWith((ref) async => data)],
      child: const MaterialApp(home: AdmissionSlipsScreen()),
    );

void main() {
  testWidgets('Needs Slip tab lists items and marks ones already requested', (tester) async {
    await tester.pumpWidget(_app(_data()));
    await tester.pumpAndSettle();

    expect(find.text('Absence'), findsWidgets);
    expect(find.text('Request pending'), findsOneWidget);
    expect(find.text('Request Slip'), findsOneWidget);
  });

  testWidgets('My Requests tab shows the Registrar note on a rejected request', (tester) async {
    await tester.pumpWidget(_app(_data()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Requests'));
    await tester.pumpAndSettle();

    expect(find.text('Attach certificate'), findsOneWidget);
  });

  testWidgets('Empty state when nothing needs a slip', (tester) async {
    await tester.pumpWidget(_app(const AdmissionSlipsData(needsSlip: [], requests: [], slips: [], badge: 0)));
    await tester.pumpAndSettle();

    expect(find.text('You are all caught up'), findsOneWidget);
  });
}
