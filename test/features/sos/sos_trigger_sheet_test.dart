import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/sos/sos_trigger_sheet.dart';

void main() {
  testWidgets('category picker requires a selection before hold-to-confirm appears',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSosTriggerSheet(context, silent: false),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Hold to confirm'), findsNothing);

    await tester.tap(find.text('Medical'));
    await tester.pump();

    expect(find.text('Hold to confirm'), findsOneWidget);
  });

  testWidgets('silent trigger shows no picker UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSosTriggerSheet(context, silent: true),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('Emergency SOS'), findsNothing);
  });
}
