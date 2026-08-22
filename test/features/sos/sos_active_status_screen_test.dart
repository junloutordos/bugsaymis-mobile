import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/sos/sos_active_status_screen.dart';
import 'package:atlasgo/src/features/sos/sos_status_provider.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    lastRequest = options;
    return ResponseBody.fromString('{}', 200, headers: {
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

  testWidgets('shows "Help is on the way" and the end-SOS action for an active alert',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sosStatusProvider(1).overrideWith((ref) => Stream.value({'status': 'acknowledged'})),
        ],
        child: const MaterialApp(home: SosActiveStatusScreen(alertId: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('Help is on the way'), findsOneWidget);
    expect(find.text("End SOS — I'm safe"), findsOneWidget);
  });

  testWidgets('shows the resolved end state and no end-SOS action once terminal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sosStatusProvider(1).overrideWith((ref) => Stream.value({'status': 'resolved'})),
        ],
        child: const MaterialApp(home: SosActiveStatusScreen(alertId: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('You are marked safe'), findsOneWidget);
    expect(find.text("End SOS — I'm safe"), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('End SOS requires confirmation before calling the end endpoint', (tester) async {
    final adapter = _RecordingAdapter();
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sosStatusProvider(1).overrideWith((ref) => Stream.value({'status': 'triggered'})),
        ],
        child: const MaterialApp(home: SosActiveStatusScreen(alertId: 1)),
      ),
    );
    await tester.pump();

    // The radar-pulse animation on this (non-terminal) status repeats
    // forever, so pumpAndSettle would never return — advance with bounded
    // pumps instead, same as the initial rendering assertions above.
    await tester.tap(find.text("End SOS — I'm safe"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(adapter.lastRequest, isNull);
    expect(find.text('End this SOS alert?'), findsOneWidget);

    await tester.tap(find.text("Yes, I'm safe"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(adapter.lastRequest?.path, '/student/portal/sos/1/end');
  });
}
