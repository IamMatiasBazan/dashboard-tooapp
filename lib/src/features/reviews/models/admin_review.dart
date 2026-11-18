class AdminReviewPerson {
  const AdminReviewPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
  final String id;
  final String firstName;
  final String lastName;
  String get fullName => '$firstName $lastName'.trim();

  factory AdminReviewPerson.fromJson(Map<String, Object?> json) =>
      AdminReviewPerson(
        id: json['id']! as String,
        firstName: json['firstName']! as String,
        lastName: json['lastName']! as String,
      );
}

class AdminReviewAuditEvent {
  const AdminReviewAuditEvent({
    required this.actorId,
    required this.action,
    required this.createdAt,
    this.id,
    this.actorName,
    this.reason,
  });
  final String actorId;
  final String? id;
  final String? actorName;
  final String action;
  final DateTime? createdAt;
  final String? reason;

  factory AdminReviewAuditEvent.fromJson(Map<String, Object?> json) {
    final actor = json['actor'] is Map<String, Object?>
        ? json['actor']! as Map<String, Object?>
        : const <String, Object?>{};
    return AdminReviewAuditEvent(
        id: json['id'] as String?,
        actorId: json['actorId'] as String? ?? actor['id'] as String? ?? '',
        actorName: '${actor['firstName'] ?? ''} ${actor['lastName'] ?? ''}'.trim(),
        action: json['action']! as String,
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
  }
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.direction,
    required this.visibility,
    required this.author,
    required this.target,
    required this.createdAt,
    this.rating,
    this.comment,
    this.contactStatus,
    this.auditEvents = const [],
  });
  final String id;
  final String direction;
  final String visibility;
  final AdminReviewPerson author;
  final AdminReviewPerson target;
  final DateTime? createdAt;
  final int? rating;
  final String? comment;
  final String? contactStatus;
  final List<AdminReviewAuditEvent> auditEvents;

  factory AdminReview.fromJson(Map<String, Object?> json) {
    final contact = json['contactIntent'];
    final events = json['auditEvents'] as List<Object?>? ?? const [];
    return AdminReview(
      id: json['id']! as String,
      direction: json['direction']! as String,
      visibility: json['visibility']! as String,
      author: AdminReviewPerson.fromJson(
        json['author']! as Map<String, Object?>,
      ),
      target: AdminReviewPerson.fromJson(
        json['target']! as Map<String, Object?>,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      contactStatus: contact is Map<String, Object?>
          ? contact['status'] as String?
          : null,
      auditEvents: events
          .whereType<Map<String, Object?>>()
          .map(AdminReviewAuditEvent.fromJson)
          .toList(growable: false),
    );
  }

  AdminReview withAuditEvents(List<AdminReviewAuditEvent> events) => AdminReview(
    id: id,
    direction: direction,
    visibility: visibility,
    author: author,
    target: target,
    createdAt: createdAt,
    rating: rating,
    comment: comment,
    contactStatus: contactStatus,
    auditEvents: events,
  );
}

class AdminReviewFilters {
  const AdminReviewFilters({
    this.visibility,
    this.providerId,
    this.authorId,
    this.rating,
    this.page = 1,
    this.limit = 20,
  });
  final String? visibility;
  final String? providerId;
  final String? authorId;
  final int? rating;
  final int page;
  final int limit;

  Map<String, Object?> toQuery() => {
    if (visibility != null) 'visibility': visibility,
    if (providerId != null && providerId!.trim().isNotEmpty)
      'providerProfileId': providerId!.trim(),
    if (authorId != null && authorId!.trim().isNotEmpty)
      'authorId': authorId!.trim(),
    if (rating != null) 'rating': rating,
    'page': page,
    'limit': limit,
  };
}

class AdminReviewPage {
  const AdminReviewPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
  final List<AdminReview> items;
  final int total;
  final int totalPages;
}
