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
  final bool hasPhoto;

  const StudentProfile({
    required this.id,
    this.barcode,
    required this.name,
    this.sex,
    this.email,
    this.gradeLevel,
    this.section,
    this.schoolYear,
    this.hasPhoto = false,
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
      hasPhoto: s['has_photo'] as bool? ?? false,
    );
  }
}

/// Every field the physical CR-80 card prints — see
/// resources/js/Pages/Students/IdCard.vue in the backend repo, the
/// print/web equivalent this mirrors.
class StudentIdCard {
  final String name;
  final String? barcode;
  final String? lrn;
  final bool hasPhoto;
  final int? gradeLevel;
  final String? section;
  final String? schoolYear;
  final String ocdName;
  final String ocdPosition;
  final String? ocdSignatureUri;
  final String? guardianName;
  final String? contactNo;
  final String? address;

  const StudentIdCard({
    required this.name,
    this.barcode,
    this.lrn,
    this.hasPhoto = false,
    this.gradeLevel,
    this.section,
    this.schoolYear,
    required this.ocdName,
    required this.ocdPosition,
    this.ocdSignatureUri,
    this.guardianName,
    this.contactNo,
    this.address,
  });

  factory StudentIdCard.fromJson(Map<String, dynamic> json) {
    final s = json['student'] as Map<String, dynamic>;
    final ocd = json['ocd'] as Map<String, dynamic>;
    final emergency = json['emergency'] as Map<String, dynamic>;
    return StudentIdCard(
      name: s['name'] as String? ?? '—',
      barcode: s['barcode'] as String?,
      lrn: s['lrn'] as String?,
      hasPhoto: s['has_photo'] as bool? ?? false,
      gradeLevel: s['grade_level'] as int?,
      section: s['section'] as String?,
      schoolYear: s['school_year'] as String?,
      ocdName: ocd['name'] as String? ?? '',
      ocdPosition: ocd['position'] as String? ?? '',
      ocdSignatureUri: ocd['signature_uri'] as String?,
      guardianName: emergency['guardian_name'] as String?,
      contactNo: emergency['contact_no'] as String?,
      address: emergency['address'] as String?,
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

final studentIdCardProvider =
    FutureProvider.autoDispose<StudentIdCard>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/id-card');
  return StudentIdCard.fromJson(response.data as Map<String, dynamic>);
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
