import '../../../core/network/api_client.dart';
import '../models/category.dart';

class CategoriesRemoteDataSource {
  const CategoriesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<CategoryPage> list(CategoryFilters filters) async {
    final rawItems = await _api.getList('/admin/categories', query: filters.toQuery());
    var categories = rawItems.map(AdminCategory.fromJson).toList(growable: false);
    if (filters.status != null) categories = categories.where((item) => item.status == filters.status).toList(growable: false);
    if (filters.active != null) categories = categories.where((item) => item.isActive == filters.active).toList(growable: false);
    if (filters.search?.trim().isNotEmpty == true) {
      final query = filters.search!.trim().toLowerCase();
      categories = categories.where((item) => item.name.toLowerCase().contains(query)).toList(growable: false);
    }
    final total = categories.length;
    final start = (filters.page - 1) * filters.limit;
    final pageItems = categories.skip(start).take(filters.limit).toList(growable: false);
    return CategoryPage(
      items: pageItems,
      page: filters.page,
      limit: filters.limit,
      total: total,
      totalPages: (total / filters.limit).ceil(),
    );
  }

  Future<void> create({
    required String name,
    String? iconUrl,
    String? csrfToken,
  }) async {
    await _api.postData(
      '/admin/categories',
      body: {'name': name, 'iconUrl': iconUrl},
      csrfToken: csrfToken,
    );
  }

  Future<void> edit(
    String id, {
    required String name,
    String? iconUrl,
    String? csrfToken,
  }) async {
    await _api.patchData(
      '/admin/categories/$id',
      body: {'name': name, 'iconUrl': iconUrl},
      csrfToken: csrfToken,
    );
  }

  Future<void> setStatus(
    String id, {
    required bool isActive,
    String? csrfToken,
  }) async {
    await _api.patchData(
      '/admin/categories/$id/active',
      body: {'isActive': isActive},
      csrfToken: csrfToken,
    );
  }

  Future<Map<String, Object?>> unify(
    String sourceId,
    String targetId, {
    String? csrfToken,
  }) => _api.postData(
    '/admin/categories/unify',
    body: {'sourceCategoryId': sourceId, 'targetCategoryId': targetId},
    csrfToken: csrfToken,
  );
}
