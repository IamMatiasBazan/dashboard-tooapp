import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/users/models/admin_user.dart';

void main() {
  test('parses an allowlisted user DTO with its locality', () {
    final user = AdminUser.fromJson({
      'id': 'user-id',
      'role': 'CLIENT',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'email': 'ada@example.test',
      'phone': '+541100000000',
      'isAccountActive': true,
      'locality': {'id': 'locality-id', 'name': 'Buenos Aires'},
      'createdAt': '2026-10-30T10:00:00.000Z',
    });

    expect(user.fullName, 'Ada Lovelace');
    expect(user.locality?.name, 'Buenos Aires');
    expect(user.isAccountActive, isTrue);
  });

  test('serializes only approved list filters', () {
    final query = AdminUserFilters(
      search: '  Ada  ',
      active: false,
      page: 2,
      limit: 10,
    ).toQuery();

    expect(query, {
      'q': 'Ada',
      'isAccountActive': 'false',
      'page': 2,
      'limit': 10,
    });
  });
}
