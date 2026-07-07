import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class GradeEntry {
  final String subjectName;
  final double? q1;
  final double? q2;
  final double? q3;
  final double? q4;
  final double? finalGe;
  final String? remarks;
  final String adjectival;
  final bool isPassed;

  const GradeEntry({
    required this.subjectName,
    this.q1,
    this.q2,
    this.q3,
    this.q4,
    this.finalGe,
    this.remarks,
    required this.adjectival,
    required this.isPassed,
  });

  factory GradeEntry.fromJson(Map<String, dynamic> json) => GradeEntry(
        subjectName: json['subject_name'] as String? ?? '—',
        q1: (json['q1'] as num?)?.toDouble(),
        q2: (json['q2'] as num?)?.toDouble(),
        q3: (json['q3'] as num?)?.toDouble(),
        q4: (json['q4'] as num?)?.toDouble(),
        finalGe: (json['final'] as num?)?.toDouble(),
        remarks: json['remarks'] as String?,
        adjectival: json['adjectival'] as String? ?? '—',
        isPassed: json['is_passed'] as bool? ?? false,
      );

  double? gradeForQuarter(int q) {
    switch (q) {
      case 1: return q1;
      case 2: return q2;
      case 3: return q3;
      case 4: return q4;
      default: return finalGe;
    }
  }
}

class GradesData {
  final String? studentName;
  final String? schoolYear;
  final List<GradeEntry> grades;

  const GradesData({
    this.studentName,
    this.schoolYear,
    required this.grades,
  });

  factory GradesData.fromJson(Map<String, dynamic> json) => GradesData(
        studentName: (json['student'] as Map<String, dynamic>?)?['name'] as String?,
        schoolYear: json['school_year'] as String?,
        grades: (json['grades'] as List)
            .map((e) => GradeEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  double? get gwa {
    final withFinal = grades.where((g) => g.finalGe != null).toList();
    if (withFinal.isEmpty) return null;
    return withFinal.fold(0.0, (s, g) => s + g.finalGe!) / withFinal.length;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final gradesProvider =
    FutureProvider.autoDispose.family<GradesData, int>((ref, studentId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/students/$studentId/grades');
  return GradesData.fromJson(response.data as Map<String, dynamic>);
});

// For student self-access (no studentId needed — server infers from token)
final studentGradesProvider =
    FutureProvider.autoDispose<GradesData>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/grades');
  return GradesData.fromJson(response.data as Map<String, dynamic>);
});
