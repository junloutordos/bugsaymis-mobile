import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';
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

  testWidgets('renders as a fully-rounded, margined card using the hero gradient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
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

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    final radius = decoration.borderRadius as BorderRadius;

    expect(decoration.gradient, AppGradients.hero);
    expect(radius.topLeft, radius.bottomLeft);
    expect(radius.topLeft, radius.topRight);
    expect(radius.topLeft.x, greaterThan(0));
    expect(container.margin, isNotNull);
  });

  testWidgets('invokes onTap when the card body is tapped, when provided', (tester) async {
    var tapped = false;
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
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Maria'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('is not tappable when onTap is not provided', (tester) async {
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

    // IconButton itself renders one internal InkWell for the action
    // button — without a card-level onTap, that's the only one. (The
    // "invokes onTap" test above proves a second one appears when onTap
    // is provided, by successfully tapping the card body and observing
    // the callback fire.)
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('trailing content left-aligns with name/subtitle, not the card edge, when leading is present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            leading: HeroBackButton(onTap: () {}),
            greeting: 'My Profile',
            name: 'Maria',
            subtitle: 'maria@example.com',
            trailing: const Text('Student'),
          ),
        ),
      ),
    );

    final nameLeft = tester.getTopLeft(find.text('Maria')).dx;
    final trailingLeft = tester.getTopLeft(find.text('Student')).dx;
    expect(trailingLeft, nameLeft);
  });
}
