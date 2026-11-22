import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../study/data/review_repository.dart';

class ReviewLogModel {
  final String id;
  final String deckTitle;
  final int rating;
  final DateTime reviewedAt;

  const ReviewLogModel({
    required this.id,
    required this.deckTitle,
    required this.rating,
    required this.reviewedAt,
  });
}

class StatsState {
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1=Again, 3=Hard, 4=Good, 5=Easy
  final List<ReviewLogModel> recentLogs;

  const StatsState({
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentLogs,
  });

  StatsState copyWith({
    int? totalReviews,
    Map<int, int>? ratingDistribution,
    List<ReviewLogModel>? recentLogs,
  }) {
    return StatsState(
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}

class StatsController extends AsyncNotifier<StatsState> {
  late ReviewRepository _repository;

  @override
  Future<StatsState> build() async {
    _repository = ref.watch(reviewRepositoryProvider);
    final summary = await _repository.getStatsSummary();

    return StatsState(
      totalReviews: summary.totalReviews,
      ratingDistribution: summary.ratingDistribution,
      recentLogs: summary.recentLogs
          .map(
            (log) => ReviewLogModel(
              id: log.id,
              deckTitle: log.deckTitle,
              rating: log.quality,
              reviewedAt: log.reviewedAt,
            ),
          )
          .toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final summary = await _repository.getStatsSummary();
      return StatsState(
        totalReviews: summary.totalReviews,
        ratingDistribution: summary.ratingDistribution,
        recentLogs: summary.recentLogs
            .map(
              (log) => ReviewLogModel(
                id: log.id,
                deckTitle: log.deckTitle,
                rating: log.quality,
                reviewedAt: log.reviewedAt,
              ),
            )
            .toList(),
      );
    });
  }
}

final statsControllerProvider =
    AsyncNotifierProvider<StatsController, StatsState>(StatsController.new);
