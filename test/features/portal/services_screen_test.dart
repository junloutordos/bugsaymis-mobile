import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:atlasgo/src/features/auth/auth_provider.dart';
import 'package:atlasgo/src/features/portal/portal_provider.dart';
import 'package:atlasgo/src/features/portal/services_screen.dart';
import 'package:atlasgo/src/shared/widgets/app_card.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: 2,
        name: 'Juan Dela Cruz',
        email: 'juan@crc.pshs.edu.ph',
        role: 'student',
      );
}

const _dashboard = PortalDashboard(
  gradeLevel: 8,
  completion: [],
  totalDone: 0,
  total: 0,
  clearance: null,
  intern: null,
);

void main() {
  testWidgets('ACCOUNT section includes the account menu entries', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          portalDashboardProvider.overrideWith((ref) async => _dashboard),
        ],
        child: const MaterialApp(home: ServicesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // The ACCOUNT section is below the fold — ListView only builds
    // visible children, so scroll it into view before asserting.
    await tester.dragUntilVisible(
      find.text('Sign out'),
      find.byType(ListView),
      const Offset(0, -300),
    );

    expect(find.text('Digital Student ID'), findsOneWidget);
    expect(find.text('Update My Information'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Each account entry is its own card, not one card with dividers.
    final idCard = find.ancestor(of: find.text('Digital Student ID'), matching: find.byType(AppCard));
    final signOutCard = find.ancestor(of: find.text('Sign out'), matching: find.byType(AppCard));
    expect(idCard, findsOneWidget);
    expect(signOutCard, findsOneWidget);
    expect(tester.widget(idCard), isNot(same(tester.widget(signOutCard))));
  });

  testWidgets('tapping Digital Student ID navigates to /student/id', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const ServicesScreen()),
      GoRoute(path: '/student/id', builder: (c, s) => const Scaffold(body: Text('ID Page'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          portalDashboardProvider.overrideWith((ref) async => _dashboard),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    // A bigger single drag (not dragUntilVisible's incremental scroll) so
    // the tile lands comfortably inside the viewport, not right at its edge.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Digital Student ID'));
    await tester.pumpAndSettle();

    expect(find.text('ID Page'), findsOneWidget);
  });
}
