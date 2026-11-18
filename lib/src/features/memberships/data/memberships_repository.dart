import '../models/admin_membership.dart';
import 'memberships_remote_data_source.dart';

class MembershipsRepository {
  const MembershipsRepository(this._remote);
  final MembershipsRemoteDataSource _remote;

  Future<AdminMembershipData> load({required bool includeArchived}) =>
      _remote.load(includeArchived: includeArchived);
  Future<AdminMembershipTier> create({
    required String name,
    required String? description,
    required int price,
    String? csrfToken,
  }) => _remote.create(
    name: name,
    description: description,
    price: price,
    csrfToken: csrfToken,
  );
  Future<AdminMembershipTier> update(
    String id, {
    required String name,
    required String? description,
    required int price,
    String? csrfToken,
  }) => _remote.update(
    id,
    name: name,
    description: description,
    price: price,
    csrfToken: csrfToken,
  );
  Future<AdminMembershipTier> archive(String id, String? csrfToken) =>
      _remote.archive(id, csrfToken);
  Future<Map<String, Object?>> assign(
    String providerId,
    String tierId,
    String? csrfToken,
  ) => _remote.assign(providerId, tierId, csrfToken);
}
