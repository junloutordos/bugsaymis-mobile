import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class NoticeItem {
  final int id;
  final String title;
  final String body;
  final String? posterPath;
  final String kind; // 'announcement' | 'emergency-alert'
  final String? severity; // only set for emergency-alert items

  NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.posterPath,
    this.severity,
  });

  factory NoticeItem.fromAnnouncementJson(Map<String, dynamic> json) => NoticeItem(
        id: json['id'] as int,
        title: json['title'] as String,
        body: (json['body'] ?? '') as String,
        posterPath: json['poster_path'] as String?,
        kind: 'announcement',
      );

  factory NoticeItem.fromEmergencyAlertJson(Map<String, dynamic> json) => NoticeItem(
        id: json['id'] as int,
        title: json['title'] as String,
        body: (json['message'] ?? '') as String,
        kind: 'emergency-alert',
        severity: json['severity'] as String?,
      );
}

class NoticesData {
  final List<NoticeItem> emergencyAlerts;
  final List<NoticeItem> announcements;

  NoticesData({required this.emergencyAlerts, required this.announcements});

  /// Emergency alerts always sort first — mirrors the web queue's priority rule.
  List<NoticeItem> get queue => [...emergencyAlerts, ...announcements];
}

final noticesProvider = FutureProvider.autoDispose<NoticesData>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/notices/pending');
  final data = response.data as Map<String, dynamic>;

  return NoticesData(
    emergencyAlerts: (data['emergency_alerts'] as List<dynamic>? ?? [])
        .map((e) => NoticeItem.fromEmergencyAlertJson(e as Map<String, dynamic>))
        .toList(),
    announcements: (data['announcements'] as List<dynamic>? ?? [])
        .map((a) => NoticeItem.fromAnnouncementJson(a as Map<String, dynamic>))
        .toList(),
  );
});

Future<void> acknowledgeNotice(ApiClient api, NoticeItem item) =>
    api.post('/notices/${item.kind}/${item.id}/acknowledge');
