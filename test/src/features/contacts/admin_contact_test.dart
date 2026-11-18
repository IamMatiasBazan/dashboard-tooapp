import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/contacts/models/admin_contact.dart';

void main() {
  test('maps contact parties and approved detail fields', () {
    final contact = AdminContact.fromJson({
      'id': 'contact-id',
      'status': 'SCHEDULED',
      'scheduledFor': '2030-01-15T00:00:00.000Z',
      'createdAt': '2026-10-30T12:00:00.000Z',
      'problemDescription': 'Revisar una instalación',
      'client': {'id': 'client-id', 'firstName': 'Ada', 'lastName': 'Lovelace'},
      'provider': {
        'id': 'provider-id',
        'user': {'firstName': 'Grace', 'lastName': 'Hopper'},
      },
      'category': {'id': 'category-id', 'name': 'Electricidad'},
    });

    expect(contact.client.fullName, 'Ada Lovelace');
    expect(contact.provider.fullName, 'Grace Hopper');
    expect(contact.provider.id, 'provider-id');
    expect(contact.category.name, 'Electricidad');
    expect(contact.scheduledFor, isNotNull);
  });

  test('serializes only selected contact filters', () {
    final query = AdminContactFilters(
      status: 'PENDING',
      providerId: 'provider-id',
      clientId: 'client-id',
      page: 2,
    ).toQuery();

    expect(query, {
      'status': 'PENDING',
      'providerProfileId': 'provider-id',
      'clientId': 'client-id',
      'page': 2,
      'limit': 20,
    });
  });
}
