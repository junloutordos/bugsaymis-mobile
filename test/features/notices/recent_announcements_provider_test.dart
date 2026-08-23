import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/notices/recent_announcements_provider.dart';

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

Map<String, dynamic> _item(int id, {bool isRead = false}) => {
      'id': id,
      'title': 'Item $id',
      'body': 'Body $id',
      'poster_path': null,
      'published_at': null,
      'is_read': isRead,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  test('fetches from /notices/history and caps at 5 even when more are returned', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _StaticAdapter(jsonEncode({
      'data': List.generate(8, (i) => _item(i)),
      'next_page_url': 'x',
    }));

    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(apiClient)]);
    addTearDown(container.dispose);

    final items = await container.read(recentAnnouncementsProvider.future);

    expect(items, hasLength(5));
    expect(items.first.title, 'Item 0');
  });

  test('includes already-read items, not just unread', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _StaticAdapter(jsonEncode({
      'data': [_item(1, isRead: true), _item(2)],
      'next_page_url': null,
    }));

    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(apiClient)]);
    addTearDown(container.dispose);

    final items = await container.read(recentAnnouncementsProvider.future);

    expect(items, hasLength(2));
    expect(items.firstWhere((i) => i.id == 1).isRead, isTrue);
    expect(items.firstWhere((i) => i.id == 2).isRead, isFalse);
  });
}
