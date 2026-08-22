import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/trend_chart.dart';

void main() {
  testWidgets('plots one spot per value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendChart(
            values: const [1.5, 2.0, 1.8, 2.4],
            labels: const ['W1', 'W2', 'W3', 'W4'],
            color: Colors.blue,
          ),
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.length, 4);
  });

  testWidgets('shows a placeholder instead of an empty chart when there is no data',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrendChart(values: [], labels: [], color: Colors.blue),
        ),
      ),
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.textContaining('No data'), findsOneWidget);
  });

  testWidgets('renders each x-axis label exactly once, never duplicated', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendChart(
            values: const [2.0, 1.75, 1.5, 1.25],
            labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
            color: Colors.blue,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Q1', 'Q2', 'Q3', 'Q4']) {
      expect(find.text(label), findsOneWidget, reason: '"$label" should appear exactly once');
    }
  });
}
