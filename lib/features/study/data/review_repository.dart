import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

/// Represents the persisted result from calling `submit_flashcard_review` RPC.
class SubmitReviewResult {
  final String reviewLogId;
  final String flashcardId;
  final int quality;
  final DateTime reviewedAt;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewAt;
  final bool alreadyProcessed;

  const SubmitReviewResult({
    required this.reviewLogId,
    required this.flashcardId,
    required this.quality,
    required this.reviewedAt,
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewAt,
    required this.alreadyProcessed,
  });

  factory SubmitReviewResult.fromJson(Map<String, dynamic> json) {
    return SubmitReviewResult(
      reviewLogId: json['review_log_id'] as String,
      flashcardId: json['flashcard_id'] as String,
      quality: (json['quality'] as num).toInt(),
      reviewedAt: DateTime.parse(json['reviewed_at'] as String),
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      intervalDays:
          (json['interval_days'] as num?)?.toInt() ??
          (json['next_interval_days'] as num?)?.toInt() ??
          1,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.parse(json['next_review_at'] as String)
          : DateTime.now(),
      alreadyProcessed: json['already_processed'] as bool? ?? false,
    );
  }
}

/// A single review log representation for stats & history.
class ReviewLogItem {
  final String id;
  final String deckTitle;
  final int quality;
  final DateTime reviewedAt;

  const ReviewLogItem({
    required this.id,
    required this.deckTitle,
    required this.quality,
    required this.reviewedAt,
  });
}

/// Aggregated statistics summary from database.
class ReviewStatsSummary {
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1, 3, 4, 5
  final List<ReviewLogItem> recentLogs;

  const ReviewStatsSummary({
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentLogs,
  });
}

/// Contract for Spaced Repetition review persistence via RPC and queries.
abstract class ReviewRepository {
  /// Submits a flashcard review atomically via `submit_flashcard_review` RPC.
  Future<SubmitReviewResult> submitReview({
    required String flashcardId,
    required int quality,
    required int repetitions,
    required int intervalDays,
    required double easeFactor,
    required DateTime reviewedAt,
    required DateTime nextReviewAt,
    required String idempotencyKey,
    required DateTime expectedUpdatedAt,
  });

  /// Retrieves aggregated review stats (total reviews, rating breakdown, recent history).
  Future<ReviewStatsSummary> getStatsSummary();

  /// Maps Supabase/RPC errors to friendly Indonesian messages.
  String mapError(Object error);
}

/// Supabase implementation calling the PostgreSQL RPC `submit_flashcard_review`.
class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _client;

  SupabaseReviewRepository(this._client);

  @override
  Future<SubmitReviewResult> submitReview({
    required String flashcardId,
    required int quality,
    required int repetitions,
    required int intervalDays,
    required double easeFactor,
    required DateTime reviewedAt,
    required DateTime nextReviewAt,
    required String idempotencyKey,
    required DateTime expectedUpdatedAt,
  }) async {
    final response = await _client.rpc(
      'submit_flashcard_review',
      params: {
        'p_flashcard_id': flashcardId,
        'p_quality': quality,
        'p_repetitions': repetitions,
        'p_interval_days': intervalDays,
        'p_ease_factor': easeFactor,
        'p_reviewed_at': reviewedAt.toUtc().toIso8601String(),
        'p_next_review_at': nextReviewAt.toUtc().toIso8601String(),
        'p_idempotency_key': idempotencyKey,
        'p_expected_updated_at': expectedUpdatedAt.toUtc().toIso8601String(),
      },
    );

    if (response is Map<String, dynamic>) {
      return SubmitReviewResult.fromJson(response);
    }

    return SubmitReviewResult.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<ReviewStatsSummary> getStatsSummary() async {
    if (_client.auth.currentSession == null) {
      return const ReviewStatsSummary(
        totalReviews: 0,
        ratingDistribution: {1: 0, 3: 0, 4: 0, 5: 0},
        recentLogs: [],
      );
    }
    // 1. Get recent review logs with deck titles via join
    final recentRows = await _client
        .from('review_logs')
        .select('id, quality, reviewed_at, flashcards(decks(title))')
        .order('reviewed_at', ascending: false)
        .limit(10);

    final recentLogs = (recentRows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final flashcard = map['flashcards'] as Map<String, dynamic>?;
      final deck = flashcard?['decks'] as Map<String, dynamic>?;
      final deckTitle = (deck?['title'] as String?) ?? 'Deck';

      return ReviewLogItem(
        id: map['id'] as String,
        deckTitle: deckTitle,
        quality: (map['quality'] as num).toInt(),
        reviewedAt: DateTime.parse(map['reviewed_at'] as String),
      );
    }).toList();

    // 2. Query rating distribution from review_logs
    final countRes = await _client
        .from('review_logs')
        .select('quality')
        .order('reviewed_at');

    final distribution = <int, int>{1: 0, 3: 0, 4: 0, 5: 0};
    int total = 0;

    for (final row in (countRes as List)) {
      final q = (row['quality'] as num?)?.toInt() ?? 0;
      if (distribution.containsKey(q)) {
        distribution[q] = distribution[q]! + 1;
        total++;
      }
    }

    return ReviewStatsSummary(
      totalReviews: total,
      ratingDistribution: distribution,
      recentLogs: recentLogs,
    );
  }

  @override
  String mapError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '40001' ||
          error.message.contains('STALE_FLASHCARD_STATE')) {
        return 'Status kartu telah berubah. Silakan coba review kembali.';
      }
      if (error.message.contains('IDEMPOTENCY_KEY_REUSED')) {
        return 'Permintaan ganda terdeteksi.';
      }
      if (error.message.contains('FLASHCARD_NOT_FOUND')) {
        return 'Flashcard tidak ditemukan atau Anda tidak memiliki akses.';
      }
      return 'Gagal menyimpan review: ${error.message}';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('handshakeexception')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    return 'Terjadi kesalahan: ${error.toString()}';
  }
}

/// In-memory mock implementation for tests and preview runs.
class MockReviewRepository implements ReviewRepository {
  final List<ReviewLogItem> _logs = [
    ReviewLogItem(
      id: 'log-1',
      deckTitle: 'Flutter & Dart Concepts',
      quality: 4,
      reviewedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ReviewLogItem(
      id: 'log-2',
      deckTitle: 'Kosakata Bahasa Jepang N5',
      quality: 5,
      reviewedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReviewLogItem(
      id: 'log-3',
      deckTitle: 'Basis Data & SQL',
      quality: 3,
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final Map<int, int> _distribution = {1: 12, 3: 20, 4: 38, 5: 17};
  int _totalReviews = 87;

  @override
  Future<SubmitReviewResult> submitReview({
    required String flashcardId,
    required int quality,
    required int repetitions,
    required int intervalDays,
    required double easeFactor,
    required DateTime reviewedAt,
    required DateTime nextReviewAt,
    required String idempotencyKey,
    required DateTime expectedUpdatedAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    _distribution[quality] = (_distribution[quality] ?? 0) + 1;
    _totalReviews++;

    final newLog = ReviewLogItem(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      deckTitle: 'Deck Sesi',
      quality: quality,
      reviewedAt: reviewedAt,
    );
    _logs.insert(0, newLog);

    return SubmitReviewResult(
      reviewLogId: 'log-${DateTime.now().millisecondsSinceEpoch}',
      flashcardId: flashcardId,
      quality: quality,
      reviewedAt: reviewedAt,
      repetitions: repetitions,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      nextReviewAt: nextReviewAt,
      alreadyProcessed: false,
    );
  }

  @override
  Future<ReviewStatsSummary> getStatsSummary() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ReviewStatsSummary(
      totalReviews: _totalReviews,
      ratingDistribution: Map.unmodifiable(_distribution),
      recentLogs: List.unmodifiable(_logs.take(10)),
    );
  }

  @override
  String mapError(Object error) => error.toString();
}

/// Riverpod provider for [ReviewRepository].
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseReviewRepository(SupabaseConfig.client);
  }
  debugPrint(
    '⚠️ [ReviewRepository] Using MockReviewRepository (Supabase not configured)',
  );
  return MockReviewRepository();
});
