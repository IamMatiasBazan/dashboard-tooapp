import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';

class UsersRemoteDataSource {
  const UsersRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AdminUserPage> list(AdminUserFilters filters) async {
    final response = await _api.dio.get<Object?>(
      '/admin/users', queryParameters: filters.toQuery(),
    );
    final body = response.data;
    if (body is! Map<String, Object?> || body['data'] is! List<Object?>) {
      throw const ApiFailure(
        null,
        'La respuesta de usuarios no tiene el formato esperado.',
      );
    }
    return AdminUserPage(
      items: (body['data']! as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(AdminUser.fromJson)
          .toList(growable: false),
      page: body['page'] as int? ?? filters.page,
      limit: body['limit'] as int? ?? filters.limit,
      total: body['total'] as int? ?? 0,
      totalPages: ((body['total'] as int? ?? 0) / filters.limit).ceil(),
    );
  }

  Future<List<AdminLocality>> localities() async =>
      (await _api.getList('/localities'))
          .map(AdminLocality.fromJson)
          .toList(growable: false);

  Future<Map<String, Object?>> update(
    String id,
    Map<String, Object?> changes,
    String? csrfToken,
  ) => _api.patchData(
      '/admin/users/$id',
      body: changes,
      csrfToken: csrfToken,
    );

  Future<Map<String, Object?>> setActive(
    String id,
    bool isActive,
    String? csrfToken,
  ) => _api.patchData(
      '/admin/users/$id/account-status',
      body: {'isAccountActive': isActive},
      csrfToken: csrfToken,
    );
}
