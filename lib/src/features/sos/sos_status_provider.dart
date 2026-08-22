import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'sos_status_poller.dart';

/// How often the active-status screen polls for updates. A separate
/// provider (rather than a hardcoded default inside sosStatusProvider) so
/// tests can override it to a near-zero delay instead of waiting on the
/// real 4s cadence.
final sosPollIntervalProvider =
    Provider<Duration>((ref) => const Duration(seconds: 4));

final sosStatusProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, int>((ref, alertId) {
  final client = ref.read(apiClientProvider);
  final interval = ref.watch(sosPollIntervalProvider);
  final poller = SosStatusPoller(
    interval: interval,
    fetch: () async {
      final response = await client.get('/student/portal/sos/$alertId');
      return response.data as Map<String, dynamic>;
    },
  );
  return poller.poll();
});

/// Calls the end-SOS endpoint. A plain function rather than a provider
/// method — invoked directly from the status screen's confirm-dialog
/// handler with whichever ApiClient the caller already has.
Future<void> endSosAlert(ApiClient apiClient, int alertId) =>
    apiClient.post('/student/portal/sos/$alertId/end');
