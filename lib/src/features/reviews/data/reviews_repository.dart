import '../models/admin_review.dart';
import 'reviews_remote_data_source.dart';

class ReviewsRepository {
  const ReviewsRepository(this._remote);
  final ReviewsRemoteDataSource _remote;

  Future<AdminReviewPage> list(AdminReviewFilters filters) =>
      _remote.list(filters);
  Future<AdminReview> get(String id) => _remote.get(id);
  Future<AdminReview> setVisibility(
    String id,
    String visibility,
    String reason,
    String? csrfToken,
  ) => _remote.setVisibility(id, visibility, reason, csrfToken);
}
