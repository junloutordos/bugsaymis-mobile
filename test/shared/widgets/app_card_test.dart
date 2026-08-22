import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/app_card.dart';

void main() {
  testWidgets('AppCard wraps a tappable child in a press-scale animation', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedScale), findsOneWidget);

    await tester.tap(find.text('content'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('AppCard without onTap renders no press-scale wrapper', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('static'))),
      ),
    );

    expect(find.byType(AnimatedScale), findsNothing);
  });
}
