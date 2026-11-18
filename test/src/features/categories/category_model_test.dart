import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/categories/models/category.dart';

void main() {
  test('maps category state and relation counts from the API DTO', () {
    final category = AdminCategory.fromJson({
      'id': 'c1',
      'name': 'Plomería',
      'status': 'APPROVED',
      'isActive': true,
      'iconUrl': null,
      'createdAt': '2026-10-30T10:00:00.000Z',
      '_count': {'primaryProviders': 3, 'secondaryProviders': 4},
    });

    expect(category.name, 'Plomería');
    expect(category.status, 'APPROVED');
    expect(category.primaryCount, 3);
    expect(category.secondaryCount, 4);
  });

  test('serializes only the selected category filters', () {
    expect(const CategoryFilters(status: 'PENDING', active: false).toQuery(), {
      'status': 'PENDING',
      'active': 'false',
    });
  });
}
