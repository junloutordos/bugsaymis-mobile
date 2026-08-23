import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlasgo/src/features/student/student_photo_image.dart';

void main() {
  testWidgets('shows the child, not CachedNetworkImage, while auth headers are still resolving', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAuthHeadersProvider.overrideWith((ref) => Completer<Map<String, String>>().future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentPhotoImage(child: Icon(Icons.person))),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('falls back to the child when auth headers fail to load', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAuthHeadersProvider.overrideWith((ref) => Future<Map<String, String>>.error('no token')),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentPhotoImage(child: Icon(Icons.person))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('renders CachedNetworkImage once auth headers resolve', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAuthHeadersProvider.overrideWith((ref) async => {'Authorization': 'Bearer test'}),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentPhotoImage(child: Icon(Icons.person))),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
