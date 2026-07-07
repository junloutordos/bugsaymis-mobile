import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ClassSlot {
  final int id;
  final String subjectName;
  final String? subjectCode;
  final String? teacherName;
  final String startTime;
  final String endTime;
  final int? durationMin;

  const ClassSlot({
    required this.id,
    required this.subjectName,
    this.subjectCode,
    this.teacherName,
    required this.startTime,
    required this.endTime,
    this.durationMin,
  });

  factory ClassSlot.fromJson(Map<String, dynamic> json) => ClassSlot(
        id: json['id'] as int,
        subjectName: json['subject_name'] as String? ?? '—',
        subjectCode: json['subject_code'] as String?,
        teacherName: json['teacher_name'] as String?,
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        durationMin: json['duration_min'] as int?,
      );
}

class ScheduleData {
  final String? studentName;
  final String? schoolYear;
  final String? sectionName;
  final int? gradeLevel;
  final Map<String, List<ClassSlot>> byDay;

  const ScheduleData({
    this.studentName,
    this.schoolYear,
    this.sectionName,
    this.gradeLevel,
    required this.byDay,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    final section = json['section'] as Map<String, dynamic>?;
    final rawSchedule = json['schedule'] as Map<String, dynamic>? ?? {};

    final byDay = rawSchedule.map((day, slots) {
      final list = (slots as List)
          .map((s) => ClassSlot.fromJson(s as Map<String, dynamic>))
          .toList();
      return MapEntry(day, list);
    });

    return ScheduleData(
      studentName: (json['student'] as Map<String, dynamic>?)?['name'] as String?,
      schoolYear: json['school_year'] as String?,
      sectionName: section?['name'] as String?,
      gradeLevel: section?['grade_level'] as int?,
      byDay: byDay,
    );
  }

  List<String> get days => byDay.keys.toList();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final scheduleProvider =
    FutureProvider.autoDispose.family<ScheduleData, int>((ref, studentId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/students/$studentId/schedule');
  return ScheduleData.fromJson(response.data as Map<String, dynamic>);
});

final studentScheduleProvider =
    FutureProvider.autoDispose<ScheduleData>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/schedule');
  return ScheduleData.fromJson(response.data as Map<String, dynamic>);
});
