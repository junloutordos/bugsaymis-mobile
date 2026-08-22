import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';
import 'package:atlasgo/src/shared/widgets/feature_icon_chip.dart';

void main() {
  testWidgets('renders the icon on a gradient-filled circle at the given size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeatureIconChip(
            icon: Icons.school_rounded,
            gradient: AppGradients.grades,
            size: 48,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.school_rounded), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth, 48);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, AppGradients.grades);
  });
}
