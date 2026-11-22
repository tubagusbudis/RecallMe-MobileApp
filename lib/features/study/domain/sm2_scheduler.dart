/// Holds the result of an SM-2 scheduling calculation.
class Sm2ScheduleResult {
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewAt;

  const Sm2ScheduleResult({
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewAt,
  });

  @override
  String toString() {
    return 'Sm2ScheduleResult(repetitions: $repetitions, intervalDays: $intervalDays, '
        'easeFactor: $easeFactor, nextReviewAt: $nextReviewAt)';
  }
}

/// Pure Dart implementation of the adapted SuperMemo 2 (SM-2) Spaced Repetition algorithm.
///
/// LOCKED MVP DECISIONS (v1.1 - D-01 s/d D-04):
/// - Initial baseline: repetitions = 0, interval_days = 0, ease_factor = 2.5, minimum ease_factor = 1.3.
/// - Rating mapping: Again = 1, Hard = 3, Good = 4, Easy = 5.
/// - When quality < 3 (Again): repetitions reset to 0, interval reset to 1 day.
/// - When quality >= 3:
///   - 1st repetition: interval = 1 day
///   - 2nd repetition: interval = 6 days
///   - 3rd+ repetition: interval = round(previous_interval * ease_factor)
/// - Ease Factor adjustment:
///   EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)), clamped to min 1.3.
class Sm2Scheduler {
  Sm2Scheduler._();

  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;

  /// Calculates the next schedule state based on the user's rating.
  ///
  /// [quality] must be 1 (Again), 3 (Hard), 4 (Good), or 5 (Easy).
  /// [reviewedAt] defaults to DateTime.now() in UTC if omitted.
  static Sm2ScheduleResult calculateNextSchedule({
    required int currentRepetitions,
    required int currentIntervalDays,
    required double currentEaseFactor,
    required int quality,
    DateTime? reviewedAt,
  }) {
    if (quality != 1 && quality != 3 && quality != 4 && quality != 5) {
      throw ArgumentError.value(
        quality,
        'quality',
        'Quality must be 1 (Again), 3 (Hard), 4 (Good), or 5 (Easy).',
      );
    }

    final reviewTime = (reviewedAt ?? DateTime.now()).toUtc();

    // 1. Calculate new Ease Factor
    // Standard SM-2 formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final q = quality;
    final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    final rawEase = currentEaseFactor + delta;
    // Clamp to minimum 1.3 and round to 3 decimal places to fit NUMERIC(5,3) in DB
    final clampedEase = (rawEase < minEaseFactor ? minEaseFactor : rawEase);
    final nextEase = (clampedEase * 1000).round() / 1000.0;

    int nextRepetitions;
    int nextInterval;

    if (quality < 3) {
      // Again (quality = 1): Failure to recall
      // Reset repetitions to 0, schedule for next day (interval = 1)
      nextRepetitions = 0;
      nextInterval = 1;
    } else {
      // Success (Hard = 3, Good = 4, Easy = 5)
      if (currentRepetitions == 0) {
        nextRepetitions = 1;
        nextInterval = 1;
      } else if (currentRepetitions == 1) {
        nextRepetitions = 2;
        nextInterval = 6;
      } else {
        nextRepetitions = currentRepetitions + 1;
        nextInterval = (currentIntervalDays * nextEase).round();
        if (nextInterval < 1) nextInterval = 1;
      }
    }

    final nextReviewAt = reviewTime.add(Duration(days: nextInterval));

    return Sm2ScheduleResult(
      repetitions: nextRepetitions,
      intervalDays: nextInterval,
      easeFactor: nextEase,
      nextReviewAt: nextReviewAt,
    );
  }
}
