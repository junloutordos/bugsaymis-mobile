import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class SlipItem {
  final String itemKey;
  final String date;
  final String label;
  final List<String> subjects;
  final String? requestStatus;

  const SlipItem({
    required this.itemKey,
    required this.date,
    required this.label,
    required this.subjects,
    this.requestStatus,
  });

  bool get canRequest => requestStatus == null;

  factory SlipItem.fromJson(Map<String, dynamic> j) => SlipItem(
        itemKey: j['item_key'] as String,
        date: j['date'] as String,
        label: j['label'] as String,
        subjects: ((j['subjects'] as List?) ?? const []).map((e) => e.toString()).toList(),
        requestStatus: j['request_status'] as String?,
      );
}

class SlipRequestItem {
  final String date;
  final String label;
  const SlipRequestItem({required this.date, required this.label});
  factory SlipRequestItem.fromJson(Map<String, dynamic> j) =>
      SlipRequestItem(date: j['date'] as String, label: j['label'] as String);
}

class SlipRequest {
  final int id;
  final String status;
  final String reason;
  final String? attachmentType;
  final bool hasDocument;
  final String? decisionNote;
  final String? createdAt;
  final List<SlipRequestItem> items;
  final List<int> slipIds;

  const SlipRequest({
    required this.id,
    required this.status,
    required this.reason,
    this.attachmentType,
    required this.hasDocument,
    this.decisionNote,
    this.createdAt,
    required this.items,
    required this.slipIds,
  });

  factory SlipRequest.fromJson(Map<String, dynamic> j) => SlipRequest(
        id: j['id'] as int,
        status: j['status'] as String,
        reason: j['reason'] as String? ?? '',
        attachmentType: j['attachment_type'] as String?,
        hasDocument: j['has_document'] == true,
        decisionNote: j['decision_note'] as String?,
        createdAt: j['created_at'] as String?,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => SlipRequestItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        slipIds: ((j['slip_ids'] as List?) ?? const []).map((e) => e as int).toList(),
      );
}

class IssuedSlip {
  final int id;
  final String infractionDate;
  final String label;
  final String excusedStatus;
  final bool hasDocument;

  const IssuedSlip({
    required this.id,
    required this.infractionDate,
    required this.label,
    required this.excusedStatus,
    required this.hasDocument,
  });

  factory IssuedSlip.fromJson(Map<String, dynamic> j) => IssuedSlip(
        id: j['id'] as int,
        infractionDate: j['infraction_date'] as String,
        label: j['label'] as String,
        excusedStatus: j['excused_status'] as String,
        hasDocument: j['has_document'] == true,
      );
}

class AdmissionSlipsData {
  final List<SlipItem> needsSlip;
  final List<SlipRequest> requests;
  final List<IssuedSlip> slips;
  final int badge;

  const AdmissionSlipsData({
    required this.needsSlip,
    required this.requests,
    required this.slips,
    required this.badge,
  });

  factory AdmissionSlipsData.fromJson(Map<String, dynamic> j) => AdmissionSlipsData(
        needsSlip: ((j['needs_slip'] as List?) ?? const [])
            .map((e) => SlipItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        requests: ((j['requests'] as List?) ?? const [])
            .map((e) => SlipRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        slips: ((j['slips'] as List?) ?? const [])
            .map((e) => IssuedSlip.fromJson(e as Map<String, dynamic>))
            .toList(),
        badge: (j['badge'] as int?) ?? 0,
      );
}

class AdmissionSlipsRepository {
  final ApiClient _api;
  AdmissionSlipsRepository(this._api);

  static const _base = '/student/portal/admission-slips';

  Future<AdmissionSlipsData> load() async {
    final r = await _api.get(_base);
    return AdmissionSlipsData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> submit({
    required List<String> itemKeys,
    required String reason,
    String? attachmentType,
    String? documentDataUri,
  }) async {
    await _api.post('$_base/requests', data: {
      'item_keys': itemKeys,
      'reason': reason,
      'attachment_type': ?attachmentType,
      'document_base64': ?documentDataUri,
    });
  }

  Future<void> cancel(int id) async {
    await _api.delete('$_base/requests/$id');
  }

  Future<List<int>> downloadSlipPdf(int slipId) async =>
      (await _api.getBytes('$_base/$slipId/pdf')).data ?? const [];
}

final admissionSlipsRepositoryProvider =
    Provider<AdmissionSlipsRepository>((ref) => AdmissionSlipsRepository(ref.read(apiClientProvider)));

final admissionSlipsProvider = FutureProvider.autoDispose<AdmissionSlipsData>(
    (ref) => ref.read(admissionSlipsRepositoryProvider).load());
