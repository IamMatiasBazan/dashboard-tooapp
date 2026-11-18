import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/reviews/models/admin_review.dart';

void main() {
  test('maps review detail and moderation history', () {
    final review = AdminReview.fromJson({
      'id': 'review-id',
      'direction': 'CLIENT_TO_PROVIDER',
      'visibility': 'HIDDEN',
      'rating': 4,
      'comment': 'Buen servicio',
      'createdAt': '2026-10-30T12:00:00.000Z',
      'author': {'id': 'author-id', 'firstName': 'Ada', 'lastName': 'Lovelace'},
      'target': {
        'id': 'provider-id',
        'firstName': 'Grace',
        'lastName': 'Hopper',
      },
      'contactIntent': {'id': 'contact-id', 'status': 'COMPLETED'},
      'auditEvents': [
        {
          'actorId': 'admin-id',
          'action': 'REVIEW_HIDDEN',
          'reason': 'Privacidad solicitada',
          'createdAt': '2026-10-30T13:00:00.000Z',
        },
      ],
    });

    expect(review.author.fullName, 'Ada Lovelace');
    expect(review.target.fullName, 'Grace Hopper');
    expect(review.visibility, 'HIDDEN');
    expect(review.auditEvents.single.reason, 'Privacidad solicitada');
  });

  test('serializes only review visibility and identity filters', () {
    expect(
      AdminReviewFilters(
        visibility: 'VISIBLE',
        providerId: ' provider-id ',
        page: 2,
      ).toQuery(),
      {
        'visibility': 'VISIBLE',
        'providerProfileId': 'provider-id',
        'page': 2,
        'limit': 20,
      },
    );
  });
}
