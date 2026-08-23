import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/notices/announcements_card.dart';

class _StaticAdapter implements HttpClientAdapter {
  final String body;
  _StaticAdapter(this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _item(int id, {bool isRead = false, String? title, String? body}) => {
      'id': id,
      'title': title ?? 'Announcement $id',
      'body': body ?? 'Body $id',
      'poster_path': null,
      'published_at': null,
      'is_read': isRead,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  testWidgets('caps the swipeable cards at 5, includes already-read items, and See all navigates to /announcements',
      (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _StaticAdapter(jsonEncode({
      'data': List.generate(7, (i) => _item(i, isRead: i.isEven)),
      'next_page_url': 'x',
    }));

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const AnnouncementsCard()),
      GoRoute(path: '/announcements', builder: (c, s) => const Scaffold(body: Text('List Page'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Item 0 is read (isEven), still shown — this is the whole point of the
    // history-backed card: it doesn't empty out once things are acknowledged.
    expect(find.text('Announcement 0'), findsOneWidget);
    expect(find.text('Announcement 5'), findsNothing);
    expect(find.text('Announcement 6'), findsNothing);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('List Page'), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail sheet for that announcement', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _StaticAdapter(jsonEncode({
      'data': [_item(1, title: 'Tap Me', body: 'Full body text.')],
      'next_page_url': null,
    }));

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const AnnouncementsCard()),
      GoRoute(path: '/announcements', builder: (c, s) => const Scaffold(body: Text('List Page'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap Me'));
    await tester.pumpAndSettle();

    expect(find.text('Full body text.'), findsOneWidget);
  });
}
