import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class PortalSection {
  final String key;
  final String label;
  final bool submitted;
  final String? submittedAt;
  final String group; // 'profile' | 'medical'

  const PortalSection({
    required this.key,
    required this.label,
    required this.submitted,
    this.submittedAt,
    required this.group,
  });

  factory PortalSection.fromJson(Map<String, dynamic> json) => PortalSection(
        key: json['key'] as String,
        label: json['label'] as String,
        submitted: json['submitted'] == true,
        submittedAt: json['submitted_at'] as String?,
        group: json['group'] as String? ?? 'profile',
      );
}

class ClearanceSummary {
  final String? periodTitle;
  final String status;
  final int done;
  final int total;
  final int pending;
  final int holds;
  final int blockers;
  final String? finalizedAt;

  const ClearanceSummary({
    this.periodTitle,
    required this.status,
    required this.done,
    required this.total,
    required this.pending,
    required this.holds,
    required this.blockers,
    this.finalizedAt,
  });

  factory ClearanceSummary.fromJson(Map<String, dynamic> json) =>
      ClearanceSummary(
        periodTitle: json['period_title'] as String?,
        status: json['status'] as String? ?? 'not_generated',
        done: (json['done'] as int?) ?? 0,
        total: (json['total'] as int?) ?? 0,
        pending: (json['pending'] as int?) ?? 0,
        holds: (json['holds'] as int?) ?? 0,
        blockers: (json['blockers'] as int?) ?? 0,
        finalizedAt: json['finalized_at'] as String?,
      );
}

class PortalDashboard {
  final String? schoolYear;
  final int gradeLevel;
  final List<PortalSection> completion;
  final int totalDone;
  final int total;
  final Map<String, dynamic>? rhApplication;
  final Map<String, dynamic>? intern;
  final ClearanceSummary? clearance;

  const PortalDashboard({
    this.schoolYear,
    required this.gradeLevel,
    required this.completion,
    required this.totalDone,
    required this.total,
    this.rhApplication,
    this.intern,
    this.clearance,
  });

  bool get isDormer => intern != null;

  factory PortalDashboard.fromJson(Map<String, dynamic> json) =>
      PortalDashboard(
        schoolYear: json['school_year'] as String?,
        gradeLevel: (json['grade_level'] as int?) ?? 0,
        completion: ((json['completion'] as List?) ?? const [])
            .map((e) => PortalSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalDone: (json['total_done'] as int?) ?? 0,
        total: (json['total'] as int?) ?? 0,
        rhApplication: json['rhApplication'] as Map<String, dynamic>?,
        intern: json['intern'] as Map<String, dynamic>?,
        clearance: json['clearanceStatus'] == null
            ? null
            : ClearanceSummary.fromJson(
                json['clearanceStatus'] as Map<String, dynamic>),
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final portalDashboardProvider =
    FutureProvider.autoDispose<PortalDashboard>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/dashboard');
  return PortalDashboard.fromJson(response.data as Map<String, dynamic>);
});

/// Guidance profile forms: existing rows + submitted map, raw from the API.
final guidanceProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/profile');
  return response.data as Map<String, dynamic>;
});

/// Medical records: existing rows + submitted map, raw from the API.
final medicalRecordsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/medical');
  return response.data as Map<String, dynamic>;
});

final rhApplicationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/rh-application');
  return response.data as Map<String, dynamic>;
});

final leavePassesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/leave-passes');
  return response.data as Map<String, dynamic>;
});

final clearanceProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/clearance');
  return response.data as Map<String, dynamic>;
});

/// Invalidate everything portal-related after a form submission.
void refreshPortal(WidgetRef ref) {
  ref.invalidate(portalDashboardProvider);
  ref.invalidate(guidanceProfileProvider);
  ref.invalidate(medicalRecordsProvider);
  ref.invalidate(rhApplicationProvider);
  ref.invalidate(leavePassesProvider);
  ref.invalidate(clearanceProvider);
}
