import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/admission_slips/admission_slips_provider.dart';
import 'package:atlasgo/src/features/admission_slips/request_slip_screen.dart';

class _FakeRepo implements AdmissionSlipsRepository {
  Map<String, dynamic>? submitted;

  @override
  Future<void> submit({
    required List<String> itemKeys,
    required String reason,
    String? attachmentType,
    String? documentDataUri,
  }) async {
    submitted = {'keys': itemKeys, 'reason': reason, 'type': attachmentType, 'doc': documentDataUri};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_FakeRepo repo, List<String> keys) => ProviderScope(
      overrides: [admissionSlipsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: RequestSlipScreen(itemKeys: keys)),
    );

void main() {
  testWidgets('reason is required before submit', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(repo, ['homeroom:5']));

    await tester.tap(find.text('Submit Request'));
    await tester.pump();

    expect(find.text('Please tell the Registrar why you were absent, late or out of class.'), findsOneWidget);
    expect(repo.submitted, isNull);
  });

  testWidgets('submits keys and reason', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(repo, ['homeroom:5', 'subject_cutting:9']));

    expect(find.text('2 item(s) selected'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'I had a fever');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(repo.submitted!['keys'], ['homeroom:5', 'subject_cutting:9']);
    expect(repo.submitted!['reason'], 'I had a fever');
    expect(repo.submitted!['doc'], isNull);
  });
}
