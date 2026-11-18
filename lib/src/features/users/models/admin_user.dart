class AdminLocality {
  const AdminLocality({required this.id, required this.name});
  final String id;
  final String name;

  factory AdminLocality.fromJson(Map<String, Object?> json) =>
      AdminLocality(id: json['id']! as String, name: json['name']! as String);
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.isAccountActive,
    required this.locality,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final bool isAccountActive;
  final AdminLocality? locality;
  final DateTime? createdAt;
  String get fullName => '$firstName $lastName'.trim();

  factory AdminUser.fromJson(Map<String, Object?> json) {
    final rawLocality = json['locality'];
    return AdminUser(
      id: json['id']! as String,
      role: json['role']! as String,
      firstName: json['firstName']! as String,
      lastName: json['lastName']! as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isAccountActive: json['isAccountActive']! as bool,
      locality: rawLocality is Map<String, Object?>
          ? AdminLocality.fromJson(rawLocality)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class AdminUserFilters {
  const AdminUserFilters({
    this.search,
    this.active,
    this.page = 1,
    this.limit = 20,
  });
  final String? search;
  final bool? active;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
    if (active != null) 'isAccountActive': active.toString(),
    'page': page,
    'limit': limit,
  };
}

class AdminUserPage {
  const AdminUserPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<AdminUser> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
