class AdminHomeSummary {
  const AdminHomeSummary({
    required this.generatedAt,
    required this.periodDays,
    required this.periodStartsAt,
    required this.periodEndsAt,
    required this.registeredUsers,
    required this.activeProviders,
    required this.publishedServices,
    required this.providersToVerify,
    required this.reportedReviews,
    required this.contactRequests,
    required this.newUsers,
    required this.newProviders,
  });

  final DateTime generatedAt;
  final int periodDays;
  final DateTime periodStartsAt;
  final DateTime periodEndsAt;
  final int registeredUsers;
  final int activeProviders;
  final int publishedServices;
  final int providersToVerify;
  final int reportedReviews;
  final int contactRequests;
  final int newUsers;
  final int newProviders;

  factory AdminHomeSummary.fromJson(Map<String, Object?> json) {
    final period = _requiredMap(json, 'period');
    final totals = _requiredMap(json, 'totals');
    final pending = _requiredMap(json, 'pending');
    final growth = _requiredMap(json, 'growth');

    return AdminHomeSummary(
      generatedAt: _requiredDate(json, 'generatedAt'),
      periodDays: _requiredInt(period, 'days'),
      periodStartsAt: _requiredDate(period, 'startsAt'),
      periodEndsAt: _requiredDate(period, 'endsAt'),
      registeredUsers: _requiredInt(totals, 'registeredUsers'),
      activeProviders: _requiredInt(totals, 'activeProviders'),
      publishedServices: _requiredInt(totals, 'publishedServices'),
      providersToVerify: _requiredInt(pending, 'providersToVerify'),
      reportedReviews: _requiredInt(pending, 'reportedReviews'),
      contactRequests: _requiredInt(pending, 'contactRequests'),
      newUsers: _requiredInt(growth, 'newUsers'),
      newProviders: _requiredInt(growth, 'newProviders'),
    );
  }
}

Map<String, Object?> _requiredMap(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is Map<String, Object?>) return value;
  throw FormatException('La respuesta del resumen no contiene "$key".');
}

int _requiredInt(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is int) return value;
  throw FormatException('La respuesta del resumen no contiene "$key".');
}

DateTime _requiredDate(Map<String, Object?> source, String key) {
  final value = source[key];
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date != null) return date;
  throw FormatException('La respuesta del resumen no contiene "$key".');
}
