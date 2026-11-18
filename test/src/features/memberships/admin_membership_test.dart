import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/memberships/models/admin_membership.dart';

void main() {
  test('maps membership tier with integer ARS price and archive state', () {
    final tier = AdminMembershipTier.fromJson({
      'id': 'tier-id',
      'name': 'Pro',
      'description': 'Plan profesional',
      'price': 12500,
      'isArchived': false,
    });

    expect(tier.price, 12500);
    expect(tier.isArchived, isFalse);
    expect(tier.description, 'Plan profesional');
  });
}
