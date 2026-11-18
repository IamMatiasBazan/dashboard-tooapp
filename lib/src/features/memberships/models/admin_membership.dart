class AdminMembershipTier {
  const AdminMembershipTier({
    required this.id,
    required this.name,
    required this.price,
    required this.isArchived,
    this.description,
  });
  final String id;
  final String name;
  final int price;
  final bool isArchived;
  final String? description;

  factory AdminMembershipTier.fromJson(Map<String, Object?> json) =>
      AdminMembershipTier(
        id: json['id']! as String,
        name: json['name']! as String,
        price: json['price']! as int,
        isArchived: json['isArchived']! as bool,
        description: json['description'] as String?,
      );
}

class AdminMembershipData {
  const AdminMembershipData({required this.tiers, required this.providers});
  final List<AdminMembershipTier> tiers;
  final List<AdminProviderOption> providers;
}

class AdminProviderOption {
  const AdminProviderOption({
    required this.id,
    required this.name,
    this.tierName,
  });
  final String id;
  final String name;
  final String? tierName;
}
