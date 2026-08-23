import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/notices/announcement_detail_sheet.dart';

void main() {
  testWidgets('renders title, formatted date, and body; hides the acknowledge button when already read', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showAnnouncementDetail(
          context,
          title: 'Foundation Day',
          body: 'Classes suspended campus-wide.',
          publishedAt: DateTime(2026, 8, 20),
          isRead: true,
        ),
        child: const Text('open'),
      ),
    ))));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Foundation Day'), findsOneWidget);
    expect(find.text('Classes suspended campus-wide.'), findsOneWidget);
    expect(find.text('August 20, 2026'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Mark as Read'), findsNothing);
  });

  testWidgets('shows a Mark as Read button that calls onAcknowledge and closes the sheet when unread', (tester) async {
    var acknowledged = false;

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showAnnouncementDetail(
          context,
          title: 'Unread Notice',
          body: 'Body text.',
          isRead: false,
          onAcknowledge: () async { acknowledged = true; },
        ),
        child: const Text('open'),
      ),
    ))));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Read'));
    await tester.pumpAndSettle();

    expect(acknowledged, isTrue);
    expect(find.text('Unread Notice'), findsNothing);
  });
}
