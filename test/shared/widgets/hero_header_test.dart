import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/shared/widgets/hero_header.dart';

void main() {
  testWidgets('renders greeting, name, subtitle, and an optional trailing stat', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            greeting: 'Good morning,',
            name: 'Maria',
            subtitle: 'Monday, August 24',
            actionIcon: Icons.person_outline_rounded,
            actionTooltip: 'Profile',
            onActionTap: () {},
            trailing: const Text('3 children linked'),
          ),
        ),
      ),
    );

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Monday, August 24'), findsOneWidget);
    expect(find.text('3 children linked'), findsOneWidget);
  });

  testWidgets('renders without a trailing widget when none is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            greeting: 'Good morning,',
            name: 'Maria',
            subtitle: 'Monday',
            actionIcon: Icons.person_outline_rounded,
            actionTooltip: 'Profile',
            onActionTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(HeroHeader), findsOneWidget);
  });

  testWidgets('tapping the action button invokes onActionTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            greeting: 'Good morning,',
            name: 'Maria',
            subtitle: 'Monday',
            actionIcon: Icons.logout_rounded,
            actionTooltip: 'Sign out',
            onActionTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
