import '../../providers/models/admin_provider.dart';

class AdminProviderAvailability {
  const AdminProviderAvailability({
    required this.providerProfileId,
    required this.isAvailable,
    required this.locationSource,
    required this.lastPulseAt,
    required this.locality,
    this.shiftEndsAt,
  });

  final String providerProfileId;
  final bool isAvailable;
  final String? locationSource;
  final DateTime? shiftEndsAt;
  final DateTime? lastPulseAt;
  final AdminProviderLocality? locality;

  factory AdminProviderAvailability.fromJson(Map<String, Object?> json) {
    final rawLocality = json['locality'];
    return AdminProviderAvailability(
      providerProfileId: json['providerProfileId']! as String,
      isAvailable: json['isAvailable']! as bool,
      locationSource: json['availabilityLocationSource'] as String?,
      shiftEndsAt: DateTime.tryParse(json['shiftEndsAt'] as String? ?? ''),
      lastPulseAt: DateTime.tryParse(json['lastPulseAt'] as String? ?? ''),
      locality: rawLocality is Map<String, Object?>
          ? AdminProviderLocality.fromJson(rawLocality)
          : null,
    );
  }
}
