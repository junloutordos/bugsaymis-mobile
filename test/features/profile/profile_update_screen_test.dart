import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/profile/profile_update_provider.dart';
import 'package:atlasgo/src/features/profile/profile_update_screen.dart';

/// Captures the last request made through it instead of hitting the network.
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
  // ApiClient reads a token via flutter_secure_storage before every request;
  // widget tests have no real platform, so the channel must be stubbed or
  // every request throws MissingPluginException before reaching the adapter.
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  testWidgets('shows a pending banner instead of the form when a request is pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileUpdateProvider.overrideWith((ref) async => {
                'current': {'contactno1': '09170000000'},
                'editable_fields': ['contactno1'],
                'pending': {
                  'requested_changes': {'contactno1': '09171234567'},
                  'submitted_at': '2026-08-22T00:00:00Z',
                },
              }),
        ],
        child: const MaterialApp(home: ProfileUpdateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('awaiting registrar review'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows an editable form when there is no pending request', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileUpdateProvider.overrideWith((ref) async => {
                'current': {'contactno1': '09170000000'},
                'editable_fields': ['contactno1'],
                'pending': null,
              }),
        ],
        child: const MaterialApp(home: ProfileUpdateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('submits only the field the student actually edited', (tester) async {
    final adapter = _RecordingAdapter();
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          profileUpdateProvider.overrideWith((ref) async => {
                'current': {'contactno1': '09170000000', 'contactno2': ''},
                'editable_fields': ['contactno1', 'contactno2'],
                'pending': null,
              }),
        ],
        child: const MaterialApp(home: ProfileUpdateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Only touch the second field — the first stays exactly as pre-filled.
    await tester.enterText(find.byType(TextFormField).last, '09179998877');
    await tester.tap(find.text('Submit for Review'));
    await tester.pumpAndSettle();

    final body = adapter.lastRequest!.data as Map;
    final changes = (body['changes'] as Map).cast<String, String>();
    expect(changes, {'contactno2': '09179998877'});
  });
}
