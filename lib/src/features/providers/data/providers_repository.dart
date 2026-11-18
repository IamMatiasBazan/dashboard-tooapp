import '../models/admin_provider.dart';
import 'providers_remote_data_source.dart';

class ProvidersRepository {
  const ProvidersRepository(this._remote);
  final ProvidersRemoteDataSource _remote;

  Future<AdminProviderPage> list(AdminProviderFilters filters) =>
      _remote.list(filters);
  Future<AdminProviderFiltersData> filters() => _remote.filters();
  Future<AdminProvider> get(String id) => _remote.get(id);
  Future<AdminProvider> update(
    String id,
    Map<String, Object?> changes,
    String? csrfToken,
  ) => _remote.update(id, changes, csrfToken);
  Future<Map<String, Object?>> setActive(
    String id,
    bool isActive,
    String? csrfToken,
  ) => _remote.setActive(id, isActive, csrfToken);
  Future<List<AdminPortfolioImage>> portfolio(String providerId) =>
      _remote.portfolio(providerId);
  Future<AdminPortfolioImage> setImageVisibility(
    String providerId,
    String imageId,
    bool isVisible,
    String reason,
    String? csrfToken,
  ) => _remote.setImageVisibility(providerId, imageId, isVisible, reason, csrfToken);
}
