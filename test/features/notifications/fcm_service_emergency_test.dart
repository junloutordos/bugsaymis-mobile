import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/notifications/fcm_service.dart';

void main() {
  test('pendingEmergencyAlertProvider starts null and can be set directly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pendingEmergencyAlertProvider), isNull);

    container.read(pendingEmergencyAlertProvider.notifier).state = {
      'type': 'emergency_alert', 'title': 'Lockdown', 'message': 'Stay indoors',
    };

    expect(container.read(pendingEmergencyAlertProvider)?['title'], 'Lockdown');
  });
}
