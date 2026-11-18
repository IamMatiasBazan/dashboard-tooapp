import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/providers/models/admin_provider.dart';

void main() {
  test('maps provider and related data without requiring sensitive fields', () {
    final provider = AdminProvider.fromJson({
      'id': 'provider-id',
      'isAvailable': false,
      'experienceYears': 5,
      'primaryCategory': {'id': 'category-id', 'name': 'Plomería'},
      'secondaryCategories': [
        {
          'category': {'id': 'secondary-id', 'name': 'Gasista'},
        },
      ],
      'user': {
        'id': 'user-id',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'phone': '+541100000000',
        'email': 'ada@example.test',
        'isAccountActive': true,
        'locality': {'id': 'locality-id', 'name': 'Moreno'},
      },
    });

    expect(provider.fullName, 'Ada Lovelace');
    expect(provider.primaryCategory.name, 'Plomería');
    expect(provider.secondaryCategories.single.name, 'Gasista');
    expect(provider.isAvailable, isFalse);
    expect(provider.isAccountActive, isTrue);
    expect(provider.locality?.name, 'Moreno');
  });

  test('maps the admin provider list DTO when phone is omitted', () {
    final provider = AdminProvider.fromJson({
      'id': 'provider-profile-id',
      'userId': 'user-id',
      'isAvailable': false,
      'primaryCategory': {'id': 'category-id', 'name': 'Plomería'},
      'user': {
        'id': 'user-id',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.test',
        'isAccountActive': true,
        'locality': {'id': 'locality-id', 'name': 'Moreno'},
      },
    });

    expect(provider.fullName, 'Ada Lovelace');
    expect(provider.phone, isNull);
    expect(provider.primaryCategory.name, 'Plomería');
    expect(provider.isAccountActive, isTrue);
  });

  test('serializes approved name, category, and locality filters', () {
    final filters = AdminProviderFilters(
      search: '  Ada ',
      categoryId: 'category-id',
      localityId: 'locality-id',
      page: 3,
    );

    expect(filters.toQuery(), {
      'q': 'Ada',
      'categoryId': 'category-id',
      'localityId': 'locality-id',
      'page': 3,
      'limit': 20,
    });
  });
}
