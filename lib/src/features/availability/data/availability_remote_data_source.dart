import '../../../core/network/api_client.dart';
import '../../providers/data/providers_remote_data_source.dart';
import '../../providers/models/admin_provider.dart';
import '../models/admin_provider_availability.dart';

class AvailabilityRemoteDataSource {
  AvailabilityRemoteDataSource(ApiClient api)
    : _api = api,
      _providers = ProvidersRemoteDataSource(api);
  final ApiClient _api;
  final ProvidersRemoteDataSource _providers;

  Future<AdminProviderPage> listProviders(String search) =>
      _providers.list(AdminProviderFilters(search: search, limit: 100));

  Future<AdminProviderAvailability> get(String providerProfileId) async =>
      AdminProviderAvailability.fromJson(
        await _api.getData('/admin/providers/$providerProfileId/availability'),
      );
}
