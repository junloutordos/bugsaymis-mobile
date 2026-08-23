import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/notices/notices_provider.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  test('parses announcements and emergency_alerts into typed notice items', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _StaticAdapter('''
      {
        "emergency_alerts": [{"id": 9, "title": "Lockdown", "message": "Stay indoors", "severity": "critical"}],
        "announcements": [{"id": 1, "title": "No classes Friday", "body": "Enjoy the break", "poster_path": null}]
      }
    ''');

    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(apiClient)]);
    addTearDown(container.dispose);

    final data = await container.read(noticesProvider.future);

    expect(data.emergencyAlerts, hasLength(1));
    expect(data.emergencyAlerts.first.kind, 'emergency-alert');
    expect(data.emergencyAlerts.first.title, 'Lockdown');
    expect(data.announcements, hasLength(1));
    expect(data.announcements.first.kind, 'announcement');
    expect(data.announcements.first.title, 'No classes Friday');
  });

  test('invalidating noticesProvider after acknowledge forces a fresh fetch, not a cached one', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _SequenceAdapter([
      '{"emergency_alerts": [], "announcements": [{"id": 1, "title": "Unread", "body": "x", "poster_path": null}]}',
      '{"emergency_alerts": [], "announcements": []}',
    ]);

    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(apiClient)]);
    addTearDown(container.dispose);

    // Keep the provider alive between reads, matching the real app: the
    // dashboard card (ref.watch) and the queue trigger (ref.listen) both
    // hold it alive for as long as the screen is mounted. A bare
    // container.read with nothing else listening lets autoDispose tear
    // it down between calls, which would refetch anyway and mask this test.
    final sub = container.listen(noticesProvider, (_, _) {});
    addTearDown(sub.close);

    final before = await container.read(noticesProvider.future);
    expect(before.announcements, hasLength(1));

    // Reading again without invalidating must NOT trigger a second HTTP
    // call — this is what the dashboard card was silently relying on
    // (stale cache) before the acknowledge flow started invalidating.
    final stillCached = await container.read(noticesProvider.future);
    expect(stillCached.announcements, hasLength(1));

    container.invalidate(noticesProvider);
    final after = await container.read(noticesProvider.future);
    expect(after.announcements, isEmpty);
  });
}
