class AdminProviderLocality {
  const AdminProviderLocality({required this.id, required this.name});
  final String id;
  final String name;

  factory AdminProviderLocality.fromJson(Map<String, Object?> json) =>
      AdminProviderLocality(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

class AdminProviderCategory {
  const AdminProviderCategory({required this.id, required this.name});
  final String id;
  final String name;

  factory AdminProviderCategory.fromJson(Map<String, Object?> json) =>
      AdminProviderCategory(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

class AdminProvider {
  const AdminProvider({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.isAccountActive,
    required this.isAvailable,
    required this.primaryCategory,
    required this.secondaryCategories,
    required this.experienceYears,
    this.email,
    this.locality,
    this.bio,
    this.isMatriculado = false,
    this.matriculaNumber,
    this.coverageRadiusKm,
    this.minPrice,
    this.chargesConsultation = false,
    this.consultationPrice,
    this.issuesInvoice = false,
    this.invoiceType,
    this.membershipTierName,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final bool isAccountActive;
  final bool isAvailable;
  final AdminProviderCategory primaryCategory;
  final List<AdminProviderCategory> secondaryCategories;
  final AdminProviderLocality? locality;
  final String? bio;
  final int experienceYears;
  final bool isMatriculado;
  final String? matriculaNumber;
  final int? coverageRadiusKm;
  final int? minPrice;
  final bool chargesConsultation;
  final int? consultationPrice;
  final bool issuesInvoice;
  final String? invoiceType;
  final String? membershipTierName;

  String get fullName => '$firstName $lastName'.trim();

  factory AdminProvider.fromJson(Map<String, Object?> json) {
    final user = json['user']! as Map<String, Object?>;
    final primary = json['primaryCategory']! as Map<String, Object?>;
    final rawLocality = user['locality'];
    final secondary = json['secondaryCategories'] as List<Object?>? ?? const [];
    final rawTier = json['membershipTier'];
    return AdminProvider(
      id: json['id']! as String,
      userId: user['id']! as String,
      firstName: user['firstName']! as String,
      lastName: user['lastName']! as String,
      phone: user['phone'] as String?,
      email: user['email'] as String?,
      isAccountActive: user['isAccountActive']! as bool,
      isAvailable: json['isAvailable']! as bool,
      primaryCategory: AdminProviderCategory.fromJson(primary),
      secondaryCategories: secondary
          .whereType<Map<String, Object?>>()
          .map(
            (item) => AdminProviderCategory.fromJson(
              item['category']! as Map<String, Object?>,
            ),
          )
          .toList(growable: false),
      locality: rawLocality is Map<String, Object?>
          ? AdminProviderLocality.fromJson(rawLocality)
          : null,
      bio: json['bio'] as String?,
      experienceYears: json['experienceYears'] as int? ?? 0,
      isMatriculado: json['isMatriculado'] as bool? ?? false,
      matriculaNumber: json['matriculaNumber'] as String?,
      coverageRadiusKm: json['coverageRadiusKm'] as int?,
      minPrice: json['minPrice'] as int?,
      chargesConsultation: json['chargesConsultation'] as bool? ?? false,
      consultationPrice: json['consultationPrice'] as int?,
      issuesInvoice: json['issuesInvoice'] as bool? ?? false,
      invoiceType: json['invoiceType'] as String?,
      membershipTierName: rawTier is Map<String, Object?>
          ? rawTier['name'] as String?
          : null,
    );
  }
}

class AdminPortfolioImage {
  const AdminPortfolioImage({
    required this.id,
    required this.imageUrl,
    required this.isVisible,
    required this.createdAt,
  });
  final String id;
  final String imageUrl;
  final bool isVisible;
  final DateTime? createdAt;

  factory AdminPortfolioImage.fromJson(Map<String, Object?> json) =>
      AdminPortfolioImage(
        id: json['id']! as String,
        imageUrl: json['imageUrl']! as String,
        isVisible: !(json['isHidden']! as bool),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class AdminProviderFilters {
  const AdminProviderFilters({
    this.search,
    this.categoryId,
    this.localityId,
    this.page = 1,
    this.limit = 20,
  });
  final String? search;
  final String? categoryId;
  final String? localityId;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
    if (categoryId != null) 'categoryId': categoryId,
    if (localityId != null) 'localityId': localityId,
    'page': page,
    'limit': limit,
  };
}

class AdminProviderPage {
  const AdminProviderPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
  final List<AdminProvider> items;
  final int total;
  final int totalPages;
}

class AdminProviderFiltersData {
  const AdminProviderFiltersData({
    required this.categories,
    required this.localities,
  });
  final List<AdminProviderCategory> categories;
  final List<AdminProviderLocality> localities;
}
