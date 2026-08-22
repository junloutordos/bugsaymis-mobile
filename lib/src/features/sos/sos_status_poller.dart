const kSosTerminalStatuses = {'resolved', 'false_alarm'};

/// Polls [fetch] on [interval] until the returned status is terminal
/// (resolved/false_alarm), then closes the stream. Extracted from the
/// Riverpod provider (sos_status_provider.dart) so the polling/stop logic
/// is testable without a real Timer or network call.
class SosStatusPoller {
  final Future<Map<String, dynamic>> Function() fetch;
  final Duration interval;

  SosStatusPoller({
    required this.fetch,
    this.interval = const Duration(seconds: 4),
  });

  Stream<Map<String, dynamic>> poll() async* {
    while (true) {
      final status = await fetch();
      yield status;
      if (kSosTerminalStatuses.contains(status['status'])) return;
      await Future.delayed(interval);
    }
  }
}
