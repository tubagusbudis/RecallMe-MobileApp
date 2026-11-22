import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/study/domain/sm2_scheduler.dart';

void main() {
  group('Sm2Scheduler domain tests', () {
    final fixedNow = DateTime.utc(2026, 11, 22, 12, 0, 0);

    test('Throws ArgumentError for disallowed quality ratings', () {
      expect(
        () => Sm2Scheduler.calculateNextSchedule(
          currentRepetitions: 0,
          currentIntervalDays: 0,
          currentEaseFactor: 2.5,
          quality: 0,
          reviewedAt: fixedNow,
        ),
        throwsArgumentError,
      );

      expect(
        () => Sm2Scheduler.calculateNextSchedule(
          currentRepetitions: 0,
          currentIntervalDays: 0,
          currentEaseFactor: 2.5,
          quality: 2,
          reviewedAt: fixedNow,
        ),
        throwsArgumentError,
      );
    });

    test('New card + Again (1): resets repetitions to 0, interval 1, EF drops by 0.54', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
        quality: 1,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 0);
      expect(res.intervalDays, 1);
      // 2.5 + (0.1 - 4 * (0.08 + 4 * 0.02)) = 2.5 + (0.1 - 0.64) = 1.96
      expect(res.easeFactor, 1.96);
      expect(res.nextReviewAt, fixedNow.add(const Duration(days: 1)));
    });

    test('New card + Hard (3): 1st repetition successful, interval 1, EF drops by 0.14', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
        quality: 3,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 1);
      expect(res.intervalDays, 1);
      // 2.5 + (0.1 - 2 * (0.08 + 2 * 0.02)) = 2.5 + (0.1 - 0.24) = 2.36
      expect(res.easeFactor, 2.36);
      expect(res.nextReviewAt, fixedNow.add(const Duration(days: 1)));
    });

    test('New card + Good (4): 1st repetition successful, interval 1, EF unchanged', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
        quality: 4,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 1);
      expect(res.intervalDays, 1);
      // 2.5 + (0.1 - 1 * (0.08 + 0.02)) = 2.5 + 0.0 = 2.5
      expect(res.easeFactor, 2.5);
      expect(res.nextReviewAt, fixedNow.add(const Duration(days: 1)));
    });

    test('New card + Easy (5): 1st repetition successful, interval 1, EF increases by 0.1', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
        quality: 5,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 1);
      expect(res.intervalDays, 1);
      // 2.5 + (0.1 - 0) = 2.6
      expect(res.easeFactor, 2.6);
      expect(res.nextReviewAt, fixedNow.add(const Duration(days: 1)));
    });

    test(
      '2nd repetition (repetitions = 1) + Good (4): interval jumps to 6 days',
      () {
        final res = Sm2Scheduler.calculateNextSchedule(
          currentRepetitions: 1,
          currentIntervalDays: 1,
          currentEaseFactor: 2.5,
          quality: 4,
          reviewedAt: fixedNow,
        );

        expect(res.repetitions, 2);
        expect(res.intervalDays, 6);
        expect(res.easeFactor, 2.5);
        expect(res.nextReviewAt, fixedNow.add(const Duration(days: 6)));
      },
    );

    test('3rd repetition (repetitions = 2, interval = 6) + Good (4): interval = round(6 * 2.5) = 15', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 2,
        currentIntervalDays: 6,
        currentEaseFactor: 2.5,
        quality: 4,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 3);
      expect(res.intervalDays, 15);
      expect(res.easeFactor, 2.5);
      expect(res.nextReviewAt, fixedNow.add(const Duration(days: 15)));
    });

    test('Experienced card failed with Again (1): repetitions reset to 0, interval to 1', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 4,
        currentIntervalDays: 25,
        currentEaseFactor: 2.6,
        quality: 1,
        reviewedAt: fixedNow,
      );

      expect(res.repetitions, 0);
      expect(res.intervalDays, 1);
      expect(res.easeFactor, 2.06); // 2.6 - 0.54
    });

    test('Ease Factor is clamped to minimum 1.3', () {
      final res = Sm2Scheduler.calculateNextSchedule(
        currentRepetitions: 1,
        currentIntervalDays: 1,
        currentEaseFactor: 1.4,
        quality: 1, // would subtract 0.54 -> 0.86 without clamp
        reviewedAt: fixedNow,
      );

      expect(res.easeFactor, 1.3);
    });
  });
}
