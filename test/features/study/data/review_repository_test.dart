import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/study/data/review_repository.dart';

void main() {
  group('MockReviewRepository tests', () {
    late MockReviewRepository repo;

    setUp(() {
      repo = MockReviewRepository();
    });

    test('getStatsSummary returns initial stats and logs', () async {
      final stats = await repo.getStatsSummary();

      expect(stats.totalReviews, 87);
      expect(stats.ratingDistribution[1], 12);
      expect(stats.ratingDistribution[3], 20);
      expect(stats.ratingDistribution[4], 38);
      expect(stats.ratingDistribution[5], 17);
      expect(stats.recentLogs.length, 3);
    });

    test('submitReview records rating and increases total count', () async {
      final now = DateTime.now().toUtc();
      final nextReview = now.add(const Duration(days: 6));

      final result = await repo.submitReview(
        flashcardId: 'card-1',
        quality: 4,
        repetitions: 2,
        intervalDays: 6,
        easeFactor: 2.5,
        reviewedAt: now,
        nextReviewAt: nextReview,
        idempotencyKey: '00000000-0000-4000-8000-000000000001',
        expectedUpdatedAt: now.subtract(const Duration(days: 1)),
      );

      expect(result.flashcardId, 'card-1');
      expect(result.quality, 4);
      expect(result.alreadyProcessed, isFalse);
      expect(result.repetitions, 2);
      expect(result.intervalDays, 6);

      final stats = await repo.getStatsSummary();
      expect(stats.totalReviews, 88);
      expect(stats.ratingDistribution[4], 39);
      expect(stats.recentLogs.first.quality, 4);
    });
  });
}
