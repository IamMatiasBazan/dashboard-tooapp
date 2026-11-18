import '../../../core/network/api_client.dart';
import '../models/admin_provider.dart';

class ProvidersRemoteDataSource {
  const ProvidersRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AdminProviderPage> list(AdminProviderFilters filters) async {
    final response = await _api.dio.get<Object?>(
      '/admin/providers', queryParameters: filters.toQuery(),
    );
    final body = response.data;
    if (body is! Map<String, Object?> || body['data'] is! List<Object?>) {
      throw const ApiFailure(
        null,
        'La respuesta de prestadores no tiene el formato esperado.',
      );
    }
    return AdminProviderPage(
      items: (body['data']! as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(AdminProvider.fromJson)
          .toList(growable: false),
      total: body['total'] as int? ?? 0,
      totalPages: ((body['total'] as int? ?? 0) / filters.limit).ceil(),
    );
  }

  Future<AdminProviderFiltersData> filters() async {
    final categories = await _api.getList(
      '/admin/categories',
      query: const {'active': 'true'},
    );
    final localities = await _api.getList('/localities');
    return AdminProviderFiltersData(
      categories: categories
          .map(AdminProviderCategory.fromJson)
          .toList(growable: false),
      localities: localities
          .map(AdminProviderLocality.fromJson)
          .toList(growable: false),
    );
  }

  Future<AdminProvider> get(String id) async =>
      AdminProvider.fromJson(await _api.getData('/admin/providers/$id'));

  Future<AdminProvider> update(
    String id,
    Map<String, Object?> changes,
    String? csrfToken,
  ) async => AdminProvider.fromJson(
    await _api.patchData(
      '/admin/providers/$id',
      body: {
        if (changes['user'] is Map<String, Object?>)
          'user': changes['user'],
        if (changes['profile'] is Map<String, Object?>)
          'providerProfile': changes['profile'],
      },
      csrfToken: csrfToken,
    ),
  );

  Future<Map<String, Object?>> setActive(
    String userId,
    bool isActive,
    String? csrfToken,
  ) => _api.patchData(
      '/admin/users/$userId/account-status',
      body: {'isAccountActive': isActive},
      csrfToken: csrfToken,
    );

  Future<List<AdminPortfolioImage>> portfolio(String providerId) async =>
      (await _api.getList('/admin/portfolio', query: {'providerProfileId': providerId}))
          .map(AdminPortfolioImage.fromJson)
          .toList(growable: false);

  Future<AdminPortfolioImage> setImageVisibility(
    String providerId,
    String imageId,
    bool isVisible,
    String reason,
    String? csrfToken,
  ) async => AdminPortfolioImage.fromJson(
    await _api.patchData(
      '/admin/portfolio/$imageId/visibility',
      body: {'isHidden': !isVisible, 'reason': reason},
      csrfToken: csrfToken,
    ),
  );
}
