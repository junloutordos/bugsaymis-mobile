import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'announcement_list_item.dart';

/// The 5 most recent published announcements, read or unread — powers the
/// dashboard card. Unlike [noticesProvider] (unread-only, drives the forced
/// notice queue modal), this must stay populated after the user acknowledges
/// everything in that queue, so the card doesn't go blank the instant they
/// clear it — confirmed as a real gap via manual testing, not a hypothetical.
final recentAnnouncementsProvider = FutureProvider.autoDispose<List<AnnouncementListItem>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/notices/history', params: {'page': 1});
  final data = response.data as Map<String, dynamic>;

  return (data['data'] as List<dynamic>)
      .map((e) => AnnouncementListItem.fromJson(e as Map<String, dynamic>))
      .take(5)
      .toList();
});
