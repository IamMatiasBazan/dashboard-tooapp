import '../../../core/network/api_client.dart';
import '../../providers/data/providers_remote_data_source.dart';
import '../../providers/models/admin_provider.dart';
import '../models/admin_membership.dart';

class MembershipsRemoteDataSource {
  MembershipsRemoteDataSource(ApiClient api)
    : _api = api,
      _providers = ProvidersRemoteDataSource(api);
  final ApiClient _api;
  final ProvidersRemoteDataSource _providers;

  Future<AdminMembershipData> load({required bool includeArchived}) async {
    final tiers = await _api.getList(
      '/admin/membership-tiers',
      query: {
        'page': 1,
        'limit': 100,
        if (!includeArchived) 'isArchived': 'false',
      },
    );
    final providers = await _providers.list(
      const AdminProviderFilters(limit: 100),
    );
    return AdminMembershipData(
      tiers: tiers.map(AdminMembershipTier.fromJson).toList(growable: false),
      providers: providers.items
          .map(
            (provider) => AdminProviderOption(
              id: provider.id,
              name: provider.fullName,
              tierName: provider.membershipTierName,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<AdminMembershipTier> create({
    required String name,
    required String? description,
    required int price,
    String? csrfToken,
  }) async => AdminMembershipTier.fromJson(
    await _api.postData(
      '/admin/membership-tiers',
      body: {'name': name, 'description': description, 'price': price},
      csrfToken: csrfToken,
    ),
  );

  Future<AdminMembershipTier> update(
    String id, {
    required String name,
    required String? description,
    required int price,
    String? csrfToken,
  }) async => AdminMembershipTier.fromJson(
    await _api.patchData(
      '/admin/membership-tiers/$id',
      body: {'name': name, 'description': description, 'price': price},
      csrfToken: csrfToken,
    ),
  );

  Future<AdminMembershipTier> archive(String id, String? csrfToken) async =>
      AdminMembershipTier.fromJson(
        await _api.patchData(
          '/admin/membership-tiers/$id/archive',
          csrfToken: csrfToken,
        ),
      );

  Future<Map<String, Object?>> assign(
    String providerId,
    String tierId,
    String? csrfToken,
  ) => _api.patchData(
    '/admin/providers/$providerId/membership',
    body: {'tierId': tierId},
    csrfToken: csrfToken,
  );
}
