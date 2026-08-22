import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/sos/sos_status_poller.dart';

void main() {
  test('polls repeatedly, emitting each status, until a terminal one arrives', () async {
    var callCount = 0;
    final statuses = ['triggered', 'acknowledged', 'resolved'];
    final poller = SosStatusPoller(
      interval: const Duration(milliseconds: 1),
      fetch: () async {
        final status = statuses[callCount];
        callCount++;
        return {'status': status};
      },
    );

    final results = await poller.poll().toList();

    expect(results.map((r) => r['status']).toList(), ['triggered', 'acknowledged', 'resolved']);
    expect(callCount, 3);
  });

  test('stops immediately if the first fetch is already terminal', () async {
    final poller = SosStatusPoller(
      interval: const Duration(milliseconds: 1),
      fetch: () async => {'status': 'false_alarm'},
    );

    final results = await poller.poll().toList();

    expect(results.length, 1);
  });
}
