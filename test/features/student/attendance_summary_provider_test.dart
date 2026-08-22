import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/student/attendance_summary_provider.dart';

class _FixedAdapter implements HttpClientAdapter {
  final String body;
  _FixedAdapter(this.body);

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

  test('parses the summary response into typed models', () async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _FixedAdapter('''
    {
      "month_present": 12,
      "month_school_days": 15,
      "month_rate": 0.8,
      "weekly": [
        {"week_start": "2026-08-03", "present": 5, "school_days": 5, "rate": 1.0},
        {"week_start": "2026-08-10", "present": 4, "school_days": 5, "rate": 0.8}
      ]
    }
    ''');

    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
    ]);
    addTearDown(container.dispose);

    final summary = await container.read(attendanceSummaryProvider.future);

    expect(summary.monthPresent, 12);
    expect(summary.monthSchoolDays, 15);
    expect(summary.monthRate, 0.8);
    expect(summary.weekly, hasLength(2));
    expect(summary.weekly.first.weekStart, '2026-08-03');
    expect(summary.weekly.last.rate, 0.8);
  });
}
