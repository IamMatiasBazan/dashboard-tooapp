import '../../../core/network/api_client.dart';
import '../models/admin_contact.dart';

class ContactsRemoteDataSource {
  const ContactsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AdminContactPage> list(AdminContactFilters filters) async {
    final response = await _api.dio.get<Object?>(
      '/admin/contact-intents', queryParameters: filters.toQuery(),
    );
    final body = response.data;
    if (body is! Map<String, Object?> || body['data'] is! List<Object?>) {
      throw const ApiFailure(
        null,
        'La respuesta de contactos no tiene el formato esperado.',
      );
    }
    final rawItems = body['data']! as List<Object?>;
    return AdminContactPage(
      items: rawItems
          .whereType<Map<String, Object?>>()
          .map(AdminContact.fromJson)
          .toList(growable: false),
      total: body['total'] as int? ?? 0,
      totalPages: ((body['total'] as int? ?? 0) / filters.limit).ceil(),
    );
  }

  Future<AdminContact> get(String id) async =>
      AdminContact.fromJson(await _api.getData('/admin/contact-intents/$id'));

  Future<AdminContact> updateStatus(
    String id,
    String status,
    String? csrfToken, {
    DateTime? scheduledFor,
  }) async => AdminContact.fromJson(
    await _api.patchData(
      '/admin/contact-intents/$id/status',
      body: {
        'status': status,
        if (scheduledFor != null)
          'scheduledFor': scheduledFor.toIso8601String(),
      },
      csrfToken: csrfToken,
    ),
  );
}
