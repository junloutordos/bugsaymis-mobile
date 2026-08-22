import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class WeeklyAttendance {
  final String weekStart;
  final int present;
  final int schoolDays;
  final double? rate;

  const WeeklyAttendance({
    required this.weekStart,
    required this.present,
    required this.schoolDays,
    this.rate,
  });

  factory WeeklyAttendance.fromJson(Map<String, dynamic> json) => WeeklyAttendance(
        weekStart: json['week_start'] as String,
        present: json['present'] as int,
        schoolDays: json['school_days'] as int,
        rate: (json['rate'] as num?)?.toDouble(),
      );
}

class AttendanceSummary {
  final int monthPresent;
  final int monthSchoolDays;
  final double? monthRate;
  final List<WeeklyAttendance> weekly;

  const AttendanceSummary({
    required this.monthPresent,
    required this.monthSchoolDays,
    this.monthRate,
    required this.weekly,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
        monthPresent: json['month_present'] as int,
        monthSchoolDays: json['month_school_days'] as int,
        monthRate: (json['month_rate'] as num?)?.toDouble(),
        weekly: (json['weekly'] as List)
            .map((e) => WeeklyAttendance.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final attendanceSummaryProvider = FutureProvider.autoDispose<AttendanceSummary>((ref) async {
  final response = await ref.read(apiClientProvider).get('/student/attendance/summary');
  return AttendanceSummary.fromJson(response.data as Map<String, dynamic>);
});
