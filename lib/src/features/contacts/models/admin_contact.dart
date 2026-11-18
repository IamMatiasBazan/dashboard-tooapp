class AdminContactParty {
  const AdminContactParty({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
  final String id;
  final String firstName;
  final String lastName;
  String get fullName => '$firstName $lastName'.trim();

  factory AdminContactParty.fromJson(Map<String, Object?> json) =>
      AdminContactParty(
        id: json['id']! as String,
        firstName: json['firstName']! as String,
        lastName: json['lastName']! as String,
      );
}

class AdminContactCategory {
  const AdminContactCategory({required this.id, required this.name});
  final String id;
  final String name;

  factory AdminContactCategory.fromJson(Map<String, Object?> json) =>
      AdminContactCategory(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

class AdminContact {
  const AdminContact({
    required this.id,
    required this.status,
    required this.client,
    required this.provider,
    required this.category,
    required this.createdAt,
    this.problemDescription,
    this.scheduledFor,
  });
  final String id;
  final String status;
  final AdminContactParty client;
  final AdminContactParty provider;
  final AdminContactCategory category;
  final String? problemDescription;
  final DateTime? scheduledFor;
  final DateTime? createdAt;

  factory AdminContact.fromJson(Map<String, Object?> json) {
    final provider = json['provider']! as Map<String, Object?>;
    final providerUser = provider['user']! as Map<String, Object?>;
    return AdminContact(
      id: json['id']! as String,
      status: json['status']! as String,
      client: AdminContactParty.fromJson(
        json['client']! as Map<String, Object?>,
      ),
      provider: AdminContactParty(
        id: provider['id']! as String,
        firstName: providerUser['firstName']! as String,
        lastName: providerUser['lastName']! as String,
      ),
      category: AdminContactCategory.fromJson(
        json['category']! as Map<String, Object?>,
      ),
      problemDescription: json['problemDescription'] as String?,
      scheduledFor: DateTime.tryParse(json['scheduledFor'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class AdminContactFilters {
  const AdminContactFilters({
    this.status,
    this.providerId,
    this.categoryId,
    this.clientId,
    this.page = 1,
    this.limit = 20,
  });
  final String? status;
  final String? providerId;
  final String? categoryId;
  final String? clientId;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    if (status != null) 'status': status,
    if (providerId != null && providerId!.isNotEmpty) 'providerProfileId': providerId,
    if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
    if (clientId != null && clientId!.isNotEmpty) 'clientId': clientId,
    'page': page,
    'limit': limit,
  };
}

class AdminContactPage {
  const AdminContactPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
  final List<AdminContact> items;
  final int total;
  final int totalPages;
}
