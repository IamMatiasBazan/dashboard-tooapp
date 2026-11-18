class ReportAuthorSummary {
  const ReportAuthorSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  String get displayName => '$firstName $lastName'.trim().isEmpty
      ? 'Autor sin nombre'
      : '$firstName $lastName'.trim();

  factory ReportAuthorSummary.fromJson(Map<String, Object?> json) =>
      ReportAuthorSummary(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );
}

class ReportFilters {
  const ReportFilters({
    this.type,
    this.isResolved,
    this.page = 1,
    this.limit = 20,
  });
  final String? type;
  final bool? isResolved;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    'type': ?type,
    if (isResolved != null) 'isResolved': isResolved.toString(),
  };
}

class ReportPage {
  const ReportPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<Report> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class Report {
  const Report({
    required this.id,
    required this.type,
    required this.content,
    required this.isResolved,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String type;
  final String content;
  final bool isResolved;
  final DateTime? createdAt;
  final ReportAuthorSummary author;

  factory Report.fromJson(Map<String, Object?> json) {
    final author = json['author'] is Map<String, Object?>
        ? json['author']! as Map<String, Object?>
        : const <String, Object?>{};
    return Report(
      id: json['id']! as String,
      type: json['type']! as String,
      content: json['content']! as String,
      isResolved: json['isResolved']! as bool,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      author: ReportAuthorSummary.fromJson(author),
    );
  }
}
