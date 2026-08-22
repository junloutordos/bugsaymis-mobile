import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/profile/profile_update_provider.dart';
import 'package:atlasgo/src/features/profile/profile_update_screen.dart';

void main() {
  testWidgets('shows a pending banner instead of the form when a request is pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileUpdateProvider.overrideWith((ref) async => {
                'current': {'contactno1': '09170000000'},
                'editable_fields': ['contactno1'],
                'pending': {
                  'requested_changes': {'contactno1': '09171234567'},
                  'submitted_at': '2026-08-22T00:00:00Z',
                },
              }),
        ],
        child: const MaterialApp(home: ProfileUpdateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('awaiting registrar review'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows an editable form when there is no pending request', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileUpdateProvider.overrideWith((ref) async => {
                'current': {'contactno1': '09170000000'},
                'editable_fields': ['contactno1'],
                'pending': null,
              }),
        ],
        child: const MaterialApp(home: ProfileUpdateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
  });
}
