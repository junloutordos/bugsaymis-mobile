import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/student/attendance_summary_provider.dart';
import 'package:atlasgo/src/features/student/student_attendance_screen.dart';
import 'package:atlasgo/src/shared/widgets/radial_progress_ring.dart';
import 'package:atlasgo/src/shared/widgets/trend_chart.dart';

/// Routes by path: the day-logs endpoint (used by a private provider this
/// test can't override directly) gets an empty-list response so its
/// loading shimmer settles instead of hanging pumpAndSettle forever.
class _PathRoutedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    final body = options.path.contains('/attendance/summary')
        ? '{"month_present": 0, "month_school_days": 0, "month_rate": null, "weekly": []}'
        : '{"date": "2026-08-22", "data": [], "pagination": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 0, "has_more": false}}';
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

  testWidgets('shows an attendance-rate ring and an 8-week trend chart', (tester) async {
    final apiClient = ApiClient();
    apiClient.dio.httpClientAdapter = _PathRoutedAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          attendanceSummaryProvider.overrideWith((ref) async => const AttendanceSummary(
                monthPresent: 12,
                monthSchoolDays: 15,
                monthRate: 0.8,
                weekly: [
                  WeeklyAttendance(weekStart: '2026-08-03', present: 5, schoolDays: 5, rate: 1.0),
                  WeeklyAttendance(weekStart: '2026-08-10', present: 4, schoolDays: 5, rate: 0.8),
                ],
              )),
        ],
        child: const MaterialApp(home: StudentAttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadialProgressRing), findsOneWidget);
    expect(find.byType(TrendChart), findsOneWidget);
  });
}
