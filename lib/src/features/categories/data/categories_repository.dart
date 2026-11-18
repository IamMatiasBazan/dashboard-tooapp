import '../models/category.dart';
import 'categories_remote_data_source.dart';

class CategoriesRepository {
  const CategoriesRepository(this._remote);
  final CategoriesRemoteDataSource _remote;

  Future<CategoryPage> list(CategoryFilters filters) => _remote.list(filters);
  Future<void> create({
    required String name,
    String? iconUrl,
    String? csrfToken,
  }) => _remote.create(name: name, iconUrl: iconUrl, csrfToken: csrfToken);
  Future<void> edit(
    String id, {
    required String name,
    String? iconUrl,
    String? csrfToken,
  }) => _remote.edit(id, name: name, iconUrl: iconUrl, csrfToken: csrfToken);
  Future<void> setStatus(
    String id, {
    required bool isActive,
    String? csrfToken,
  }) => _remote.setStatus(
    id,
    isActive: isActive,
    csrfToken: csrfToken,
  );
  Future<Map<String, Object?>> unify(
    String sourceId,
    String targetId, {
    String? csrfToken,
  }) => _remote.unify(sourceId, targetId, csrfToken: csrfToken);
}
