import '../../../core/network/api_client.dart';
import '../models/admin_review.dart';

class ReviewsRemoteDataSource {
  const ReviewsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AdminReviewPage> list(AdminReviewFilters filters) async {
    final response = await _api.dio.get<Object?>(
      '/admin/reviews', queryParameters: filters.toQuery(),
    );
    final body = response.data;
    if (body is! Map<String, Object?> || body['data'] is! List<Object?>) {
      throw const ApiFailure(
        null,
        'La respuesta de reseñas no tiene el formato esperado.',
      );
    }
    final items = (body['data']! as List<Object?>)
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    final reviews = items.map(AdminReview.fromJson).toList(growable: false);
    final total = body['total'] as int? ?? 0;
    return AdminReviewPage(
      items: reviews,
      total: total,
      totalPages: ((total) / filters.limit).ceil(),
    );
  }

  Future<AdminReview> get(String id) async {
    final detail = await _api.getData('/admin/reviews/$id');
    final audit = await _api.getList('/admin/reviews/$id/audit');
    return AdminReview.fromJson(detail).withAuditEvents(
      audit.map(AdminReviewAuditEvent.fromJson).toList(growable: false),
    );
  }

  Future<AdminReview> setVisibility(
    String id,
    String visibility,
    String reason,
    String? csrfToken,
  ) async => AdminReview.fromJson(
    await _api.patchData(
      '/admin/reviews/$id/visibility',
      body: {'visibility': visibility, 'reason': reason},
      csrfToken: csrfToken,
    ),
  );
}
