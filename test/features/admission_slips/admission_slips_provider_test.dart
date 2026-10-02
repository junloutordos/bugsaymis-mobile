import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/admission_slips/admission_slips_provider.dart';
import 'package:atlasgo/src/features/portal/portal_provider.dart';

void main() {
  test('AdmissionSlipsData parses the API contract', () {
    final data = AdmissionSlipsData.fromJson({
      'needs_slip': [
        {'item_key': 'homeroom:5', 'date': '2026-08-12', 'infraction_type': 'absence', 'label': 'Absence', 'subjects': ['Filipino'], 'request_status': null},
        {'item_key': 'subject_cutting:9', 'date': '2026-08-13', 'infraction_type': 'cut_class', 'label': 'Cut Class', 'subjects': [], 'request_status': 'pending'},
      ],
      'requests': [
        {'id': 3, 'status': 'rejected', 'reason': 'Fever', 'attachment_type': 'medical_certificate', 'has_document': true,
         'decision_note': 'Attach certificate', 'reviewed_at': '2026-08-14T01:00:00+08:00', 'created_at': '2026-08-13T01:00:00+08:00',
         'items': [{'date': '2026-08-12', 'label': 'Absence'}], 'slip_ids': []},
      ],
      'slips': [
        {'id': 7, 'infraction_date': '2026-08-01', 'label': 'Tardy', 'excused_status': 'excused', 'issued_at': '2026-08-02T01:00:00+08:00', 'has_document': false},
      ],
      'badge': 1,
    });

    expect(data.badge, 1);
    expect(data.needsSlip.first.itemKey, 'homeroom:5');
    expect(data.needsSlip.first.canRequest, isTrue);
    expect(data.needsSlip[1].canRequest, isFalse); // already has a pending request
    expect(data.requests.single.decisionNote, 'Attach certificate');
    expect(data.requests.single.items.single.label, 'Absence');
    expect(data.slips.single.excusedStatus, 'excused');
  });

  test('AdmissionSlipsData tolerates missing optional fields', () {
    final data = AdmissionSlipsData.fromJson({'needs_slip': [], 'requests': [], 'slips': []});
    expect(data.badge, 0);
    expect(data.needsSlip, isEmpty);
  });

  test('PortalDashboard reads admission_slip_badge and defaults to 0', () {
    expect(PortalDashboard.fromJson({'admission_slip_badge': 3}).admissionSlipBadge, 3);
    expect(PortalDashboard.fromJson({}).admissionSlipBadge, 0);
  });
}
