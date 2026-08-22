import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/radial_progress_ring.dart';

void main() {
  testWidgets('renders the given center content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadialProgressRing(
            value: 3,
            max: 4,
            colors: const [Colors.blue, Colors.green],
            center: const Text('75%'),
          ),
        ),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('sizes itself to the given size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadialProgressRing(
            value: 1,
            max: 2,
            colors: const [Colors.blue, Colors.green],
            size: 80,
          ),
        ),
      ),
    );

    final box = tester.getSize(find.byType(RadialProgressRing));
    expect(box.width, 80);
    expect(box.height, 80);
  });

  testWidgets('renders without error when max is zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadialProgressRing(
            value: 0,
            max: 0,
            colors: const [Colors.blue, Colors.green],
          ),
        ),
      ),
    );

    expect(find.byType(RadialProgressRing), findsOneWidget);
  });
}
