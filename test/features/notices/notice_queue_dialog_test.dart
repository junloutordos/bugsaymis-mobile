import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/notices/notice_queue_dialog.dart';

/// Serves a scripted sequence of GET responses to /notices/pending (one per
/// call, including the refetches ref.invalidate triggers), a harmless static
/// empty response to /notices/history (recentAnnouncementsProvider also
/// refetches on acknowledge, but its content is irrelevant to this test —
/// routing by path keeps that traffic from consuming pendingBodies slots),
/// and accepts every POST (acknowledge) with a trivial 200.
class _RoutedGetAdapter implements HttpClientAdapter {
  final List<String> pendingBodies;
  int _pendingCall = 0;
  _RoutedGetAdapter(this.pendingBodies);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    if (options.method == 'POST') {
      return ResponseBody.fromString('{}', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    if (options.path.contains('/notices/history')) {
      return ResponseBody.fromString(jsonEncode({'data': [], 'next_page_url': null}), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    final body = pendingBodies[_pendingCall.clamp(0, pendingBodies.length - 1)];
    _pendingCall++;
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _pending(List<int> ids) => {
      'emergency_alerts': [],
      'announcements': [
        for (final id in ids) {'id': id, 'title': 'Notice $id', 'body': 'Body $id', 'poster_path': null},
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  testWidgets('acknowledging one item never shows a second overlapping dialog for the next item', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _RoutedGetAdapter([
      jsonEncode(_pending([1, 2, 3])),
      // ref.invalidate(noticesProvider) inside onAcknowledge triggers this
      // refetch — the bug this test guards against is watchPendingNotices'
      // ref.listen reacting to it as if it were a brand-new queue arriving.
      jsonEncode(_pending([2, 3])),
      jsonEncode(_pending([3])),
      jsonEncode(_pending([])),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(builder: (context, ref, _) {
              watchPendingNotices(context, ref);
              return const SizedBox();
            }),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(NoticeQueueDialog), findsOneWidget);
    expect(find.text('Notice 1'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Read'));
    await tester.pumpAndSettle();

    // The core regression check: exactly one dialog, not two stacked on top
    // of each other (which is what made the background look black and the
    // notice appear to "loop" — two independent _showQueue recursions both
    // trying to display the same next item).
    expect(find.byType(NoticeQueueDialog), findsOneWidget);
    expect(find.text('Notice 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Read'));
    await tester.pumpAndSettle();

    expect(find.byType(NoticeQueueDialog), findsOneWidget);
    expect(find.text('Notice 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Read'));
    await tester.pumpAndSettle();

    expect(find.byType(NoticeQueueDialog), findsNothing);
  });
}
