class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
    this.iconUrl,
    this.createdAt,
    this.primaryCount = 0,
    this.secondaryCount = 0,
  });

  final String id;
  final String name;
  final String status;
  final bool isActive;
  final String? iconUrl;
  final DateTime? createdAt;
  final int primaryCount;
  final int secondaryCount;

  factory AdminCategory.fromJson(Map<String, Object?> json) {
    final count = json['_count'] is Map<String, Object?>
        ? json['_count']! as Map<String, Object?>
        : const <String, Object?>{};
    return AdminCategory(
      id: json['id']! as String,
      name: json['name']! as String,
      status: json['status']! as String,
      isActive: json['isActive']! as bool,
      iconUrl: json['iconUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      primaryCount: count['primaryProviders'] as int? ?? 0,
      secondaryCount: count['secondaryProviders'] as int? ?? 0,
    );
  }
}

class CategoryFilters {
  const CategoryFilters({
    this.status,
    this.active,
    this.search,
    this.page = 1,
    this.limit = 20,
  });
  final String? status;
  final bool? active;
  final String? search;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    'status': ?status,
    if (active != null) 'active': active.toString(),
  };
}

class CategoryPage {
  const CategoryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<AdminCategory> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
