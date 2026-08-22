import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/pressable.dart';

void main() {
  testWidgets('wraps a tappable child in a press-scale animation and calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pressable(
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

  testWidgets('scales down while pressed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pressable(onTap: () {}, child: const Text('content')),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('content')));
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, lessThan(1.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
