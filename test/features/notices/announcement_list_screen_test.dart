import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/notices/announcement_list_screen.dart';

class _SequenceAdapter implements HttpClientAdapter {
  final List<String> bodies;
  int _call = 0;
  _SequenceAdapter(this.bodies);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    final body = bodies[_call.clamp(0, bodies.length - 1)];
    _call++;
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _item(int id) =>
    {'id': id, 'title': 'Item $id', 'body': 'Body $id', 'poster_path': null, 'published_at': null, 'is_read': false};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  testWidgets('shows an empty state when there are no announcements', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter =
        _SequenceAdapter([jsonEncode({'data': [], 'next_page_url': null})]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(home: AnnouncementListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No announcements yet.'), findsOneWidget);
  });

  testWidgets('loads the first page and tapping a tile opens the detail sheet', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _SequenceAdapter([
      jsonEncode({'data': [_item(1)], 'next_page_url': null}),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(home: AnnouncementListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);

    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    expect(find.text('Body 1'), findsOneWidget);
  });

  testWidgets('scrolling near the bottom loads the next page', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _SequenceAdapter([
      jsonEncode({
        'data': List.generate(15, (i) => _item(i)),
        'next_page_url': 'x',
      }),
      jsonEncode({
        'data': [_item(15)],
        'next_page_url': null,
      }),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(home: AnnouncementListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsOneWidget);

    await tester.drag(find.byType(GridView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(find.text('Item 15'), findsOneWidget);
  });
}
