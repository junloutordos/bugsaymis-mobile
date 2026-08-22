import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/staggered_list.dart';

void main() {
  testWidgets('renders all children immediately and staggers their fade-in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StaggeredList(children: [Text('one'), Text('two'), Text('three')]),
        ),
      ),
    );

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);

    // The last item's delay (80ms) can't have elapsed yet — it must not be
    // fully faded in immediately after the first pump, proving items
    // stagger in rather than all animating in at once.
    final lastOpacity =
        tester.widget<FadeTransition>(find.byType(FadeTransition).last).opacity.value;
    expect(lastOpacity, lessThan(1.0));

    await tester.pumpAndSettle();

    for (final finder in find.byType(FadeTransition).evaluate()) {
      final widget = finder.widget as FadeTransition;
      expect(widget.opacity.value, 1.0);
    }
  });
}
