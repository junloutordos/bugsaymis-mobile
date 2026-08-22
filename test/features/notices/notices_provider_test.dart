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
}
