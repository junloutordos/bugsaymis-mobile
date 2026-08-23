import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlasgo/src/features/notices/announcement_poster_image.dart';
import 'package:atlasgo/src/features/notices/notices_provider.dart';

void main() {
  testWidgets('shows a placeholder, not CachedNetworkImage, while auth headers are still resolving', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posterAuthHeadersProvider.overrideWith((ref) => Completer<Map<String, String>>().future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnnouncementPosterImage(posterPath: 'announcements/1.jpg')),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('falls back to the campaign-icon placeholder when auth headers fail to load', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posterAuthHeadersProvider.overrideWith((ref) => Future<Map<String, String>>.error('no token')),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnnouncementPosterImage(posterPath: 'announcements/1.jpg')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
