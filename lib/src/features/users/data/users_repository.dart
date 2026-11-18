import '../models/admin_user.dart';
import 'users_remote_data_source.dart';

class UsersRepository {
  const UsersRepository(this._remote);
  final UsersRemoteDataSource _remote;

  Future<AdminUserPage> list(AdminUserFilters filters) => _remote.list(filters);
  Future<List<AdminLocality>> localities() => _remote.localities();
  Future<Map<String, Object?>> update(
    String id,
    Map<String, Object?> changes,
    String? csrfToken,
  ) => _remote.update(id, changes, csrfToken);
  Future<Map<String, Object?>> setActive(String id, bool isActive, String? csrfToken) =>
      _remote.setActive(id, isActive, csrfToken);
}
