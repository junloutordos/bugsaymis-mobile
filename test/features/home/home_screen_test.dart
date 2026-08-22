import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';
import 'package:atlasgo/src/features/auth/auth_provider.dart';
import 'package:atlasgo/src/features/home/home_provider.dart';
import 'package:atlasgo/src/features/home/home_screen.dart';
import 'package:atlasgo/src/shared/widgets/hero_header.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: 1,
        name: 'Maria Santos',
        email: 'maria@crc.pshs.edu.ph',
        role: 'parent',
      );
}

void main() {
  testWidgets('shows a HeroHeader with the linked-student count, no AppHeader', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          linkedStudentsProvider.overrideWith((ref) async => const [
                LinkedStudent(id: 1, barcode: 'B1', fullName: 'Juan Dela Cruz'),
              ]),
          todaySummaryProvider(1).overrideWith((ref) async => const TodaySummary(
                studentId: 1,
                studentName: 'Juan Dela Cruz',
                date: '2026-08-24',
                lastStatus: 'in',
                totalScans: 1,
                logs: [],
              )),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.byType(AppHeader), findsNothing);
    expect(find.textContaining('1 child linked'), findsOneWidget);
  });

  testWidgets('still shows the empty state when no students are linked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          linkedStudentsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No children linked yet'), findsOneWidget);
  });
}
