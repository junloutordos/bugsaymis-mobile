import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class StudentProfile {
  final int id;
  final String? barcode;
  final String name;
  final String? sex;
  final String? email;
  final int? gradeLevel;
  final String? section;
  final String? schoolYear;

  const StudentProfile({
    required this.id,
    this.barcode,
    required this.name,
    this.sex,
    this.email,
    this.gradeLevel,
    this.section,
    this.schoolYear,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final s = json['student'] as Map<String, dynamic>;
    return StudentProfile(
      id: s['id'] as int,
      barcode: s['barcode'] as String?,
      name: s['name'] as String? ?? '—',
      sex: s['sex'] as String?,
      email: s['email'] as String?,
      gradeLevel: s['grade_level'] as int?,
      section: s['section'] as String?,
      schoolYear: s['school_year'] as String?,
    );
  }
}

class StudentTodaySummary {
  final String? lastStatus;
  final String? lastScan;
  final int totalScans;

  const StudentTodaySummary({
    this.lastStatus,
    this.lastScan,
    required this.totalScans,
  });

  factory StudentTodaySummary.fromJson(Map<String, dynamic> json) =>
      StudentTodaySummary(
        lastStatus: json['last_status'] as String?,
        lastScan: json['last_scan'] as String?,
        totalScans: (json['total_scans'] as int?) ?? 0,
      );
}

final studentProfileProvider =
    FutureProvider.autoDispose<StudentProfile>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/profile');
  return StudentProfile.fromJson(response.data as Map<String, dynamic>);
});

final studentTodayProvider =
    FutureProvider.autoDispose<StudentTodaySummary>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/attendance', params: {
    'date': DateTime.now().toIso8601String().split('T').first,
  });
  final data = response.data as Map<String, dynamic>;
  final logs = data['data'] as List;
  final last = logs.isNotEmpty ? logs.last as Map<String, dynamic> : null;
  return StudentTodaySummary(
    lastStatus: last?['type'] as String?,
    lastScan: last?['scan_time'] as String?,
    totalScans: logs.length,
  );
});
