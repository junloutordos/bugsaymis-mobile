import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:atlasgo/src/core/page_transition.dart';

void main() {
  testWidgets('wraps the pushed page in a Fade + Scale transition', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('home'))),
      GoRoute(
        path: '/detail',
        pageBuilder: (c, s) => appPageTransition(
          pageKey: s.pageKey,
          child: const Scaffold(body: Text('detail')),
        ),
      ),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsWidgets);
    expect(find.text('detail'), findsOneWidget);
  });
}
