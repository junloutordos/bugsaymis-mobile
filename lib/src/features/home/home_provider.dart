import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../auth/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class TodaySummary {
  final int studentId;
  final String studentName;
  final String date;
  final String? lastStatus;   // 'in' | 'out' | null
  final String? lastScan;
  final int totalScans;
  final List<ScanEntry> logs;

  const TodaySummary({
    required this.studentId,
    required this.studentName,
    required this.date,
    this.lastStatus,
    this.lastScan,
    required this.totalScans,
    required this.logs,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) => TodaySummary(
        studentId: json['student']['id'],
        studentName: json['student']['name'],
        date: json['date'],
        lastStatus: json['last_status'],
        lastScan: json['last_scan'],
        totalScans: json['total_scans'],
        logs: (json['logs'] as List)
            .map((e) => ScanEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ScanEntry {
  final String type;
  final String typeLabel;
  final String scanTime;
  final String? gateLocation;

  const ScanEntry({
    required this.type,
    required this.typeLabel,
    required this.scanTime,
    this.gateLocation,
  });

  factory ScanEntry.fromJson(Map<String, dynamic> json) => ScanEntry(
        type: json['type'],
        typeLabel: json['type_label'],
        scanTime: json['scan_time'],
        gateLocation: json['gate_location'],
      );
}

class LinkedStudent {
  final int id;
  final String barcode;
  final String fullName;
  final String? sex;
  final String? relationship;

  const LinkedStudent({
    required this.id,
    required this.barcode,
    required this.fullName,
    this.sex,
    this.relationship,
  });

  factory LinkedStudent.fromJson(Map<String, dynamic> json) => LinkedStudent(
        id: json['id'],
        barcode: json['barcode'] ?? '',
        fullName: json['full_name'] ?? '',
        sex: json['sex'],
        relationship: json['relationship'],
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final linkedStudentsProvider =
    FutureProvider.autoDispose<List<LinkedStudent>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final client = ref.read(apiClientProvider);
  final response = await client.get('/students');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List;
  return list.map((e) => LinkedStudent.fromJson(e as Map<String, dynamic>)).toList();
});

final todaySummaryProvider =
    FutureProvider.autoDispose.family<TodaySummary, int>((ref, studentId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/attendance/$studentId/today');
  return TodaySummary.fromJson(response.data as Map<String, dynamic>);
});

// ── Link Requests (pending confirmations) ─────────────────────────────────────

class LinkRequest {
  final int id;
  final String maskedStudentId;
  final String relationship;
  final String status;
  final String createdAt;

  const LinkRequest({
    required this.id,
    required this.maskedStudentId,
    required this.relationship,
    required this.status,
    required this.createdAt,
  });

  factory LinkRequest.fromJson(Map<String, dynamic> json) => LinkRequest(
        id: json['id'],
        maskedStudentId: json['masked_student_id'] ?? '****',
        relationship: json['relationship'] ?? 'guardian',
        status: json['status'] ?? 'pending',
        createdAt: json['created_at'] ?? '',
      );
}

final linkRequestsProvider =
    FutureProvider.autoDispose<List<LinkRequest>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final client = ref.read(apiClientProvider);
  final response = await client.get('/link-requests');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List;
  return list.map((e) => LinkRequest.fromJson(e as Map<String, dynamic>)).toList();
});
