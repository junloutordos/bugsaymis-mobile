import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/sos/sos_status_provider.dart';

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
  // ApiClient reads a token via flutter_secure_storage before every
  // request; this plain test has no platform, so the channel must be
  // stubbed or every request throws MissingPluginException.
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  test('emits each polled status and stops once terminal', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _SequenceAdapter([
      '{"status": "triggered"}',
      '{"status": "acknowledged"}',
      '{"status": "resolved"}',
    ]);

    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      sosPollIntervalProvider.overrideWithValue(const Duration(milliseconds: 5)),
    ]);
    addTearDown(container.dispose);

    final statuses = <String>[];
    final done = Completer<void>();
    final sub = container.listen(sosStatusProvider(1), (prev, next) {
      next.whenData((data) {
        statuses.add(data['status'] as String);
        if (data['status'] == 'resolved') done.complete();
      });
    }, fireImmediately: true);
    addTearDown(sub.close);

    await done.future.timeout(const Duration(seconds: 2));
    expect(statuses, ['triggered', 'acknowledged', 'resolved']);
  });
}
