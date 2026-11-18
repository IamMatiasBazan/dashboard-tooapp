import '../../../core/network/api_client.dart';
import '../models/admin_account.dart';

class AdminAccountsRemoteDataSource {
  const AdminAccountsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AdminAccountPage> list(AdminAccountFilters filters) async {
    final body = await _api.getPage(
      '/admin/accounts',
      query: filters.toQuery(),
    );
    final rows = body['data'];
    if (rows is! List<Object?>) {
      throw const ApiFailure(
        null,
        'La respuesta de cuentas no tiene el formato esperado.',
      );
    }
    final total = body['total'] as int? ?? 0;
    return AdminAccountPage(
      items: rows
          .whereType<Map<String, Object?>>()
          .map(AdminAccount.fromJson)
          .toList(growable: false),
      page: body['page'] as int? ?? filters.page,
      limit: body['limit'] as int? ?? filters.limit,
      total: total,
      totalPages: (total / filters.limit).ceil(),
    );
  }

  Future<List<AdminAccountLocality>> localities() async =>
      (await _api.getList('/localities'))
          .map(AdminAccountLocality.fromJson)
          .toList(growable: false);
  Future<List<AdminAccountCategory>> categories() async =>
      (await _api.getList('/admin/categories'))
          .map(AdminAccountCategory.fromJson)
          .toList(growable: false);
}
