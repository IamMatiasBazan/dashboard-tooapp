class AdminAccountLocality {
  const AdminAccountLocality({required this.id, required this.name});
  final String id;
  final String name;
  factory AdminAccountLocality.fromJson(Map<String, Object?> json) =>
      AdminAccountLocality(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

class AdminAccountCategory {
  const AdminAccountCategory({required this.id, required this.name});
  final String id;
  final String name;
  factory AdminAccountCategory.fromJson(Map<String, Object?> json) =>
      AdminAccountCategory(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

enum AdminAccountType { client, provider }

class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.type,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isAccountActive,
    required this.createdAt,
    this.locality,
    this.providerProfile,
  });
  final String id;
  final AdminAccountType type;
  final String firstName;
  final String lastName;
  final String? email;
  final bool isAccountActive;
  final DateTime? createdAt;
  final AdminAccountLocality? locality;
  final AdminAccountProviderProfile? providerProfile;
  String get fullName => '$firstName $lastName'.trim();
  String? get primaryCategoryName => providerProfile?.primaryCategory?.name;
  bool? get isAvailable => providerProfile?.isAvailable;

  factory AdminAccount.fromJson(Map<String, Object?> json) {
    final rawLocality = json['locality'];
    final rawProvider = json['providerProfile'];
    return AdminAccount(
      id: json['id']! as String,
      type: switch (json['accountType']) {
        'CLIENT' => AdminAccountType.client,
        'PROVIDER' => AdminAccountType.provider,
        _ => throw const FormatException('Tipo de cuenta desconocido.'),
      },
      firstName: json['firstName']! as String,
      lastName: json['lastName']! as String,
      email: json['email'] as String?,
      isAccountActive: json['isAccountActive']! as bool,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      locality: rawLocality is Map<String, Object?>
          ? AdminAccountLocality.fromJson(rawLocality)
          : null,
      providerProfile: rawProvider is Map<String, Object?>
          ? AdminAccountProviderProfile.fromJson(rawProvider)
          : null,
    );
  }
}

class AdminAccountProviderProfile {
  const AdminAccountProviderProfile({
    required this.id,
    required this.primaryCategory,
    required this.isAvailable,
  });
  final String id;
  final AdminAccountCategory? primaryCategory;
  final bool isAvailable;
  factory AdminAccountProviderProfile.fromJson(Map<String, Object?> json) {
    final category = json['primaryCategory'];
    return AdminAccountProviderProfile(
      id: json['id']! as String,
      primaryCategory: category is Map<String, Object?>
          ? AdminAccountCategory.fromJson(category)
          : null,
      isAvailable: json['isAvailable']! as bool,
    );
  }
}

class AdminAccountFilters {
  const AdminAccountFilters({
    this.search,
    this.type,
    this.isAccountActive,
    this.localityId,
    this.categoryId,
    this.isAvailable,
    this.page = 1,
    this.limit = 20,
  });
  final String? search;
  final AdminAccountType? type;
  final bool? isAccountActive;
  final String? localityId;
  final String? categoryId;
  final bool? isAvailable;
  final int page;
  final int limit;
  Map<String, Object?> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
    if (type != null)
      'accountType': type == AdminAccountType.client ? 'CLIENT' : 'PROVIDER',
    if (isAccountActive != null) 'isAccountActive': isAccountActive.toString(),
    if (localityId != null) 'localityId': localityId,
    if (categoryId != null) 'categoryId': categoryId,
    if (isAvailable != null) 'isAvailable': isAvailable.toString(),
    'page': page,
    'limit': limit,
  };
}

class AdminAccountPage {
  const AdminAccountPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<AdminAccount> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
