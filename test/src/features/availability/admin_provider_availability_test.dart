import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/availability/models/admin_provider_availability.dart';

void main() {
  test(
    'maps read-only locality and availability summary without coordinates',
    () {
      final availability = AdminProviderAvailability.fromJson({
        'providerProfileId': 'provider-id',
        'isAvailable': true,
        'availabilityLocationSource': 'BASE',
        'shiftEndsAt': '2030-01-15T18:00:00.000Z',
        'lastPulseAt': '2030-01-15T10:00:00.000Z',
        'locality': {'id': 'locality-id', 'name': 'Moreno'},
      });

      expect(availability.providerProfileId, 'provider-id');
      expect(availability.isAvailable, isTrue);
      expect(availability.locality?.name, 'Moreno');
      expect(availability.locationSource, 'BASE');
    },
  );
}
