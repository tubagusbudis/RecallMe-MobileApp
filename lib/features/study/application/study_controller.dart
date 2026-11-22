import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/uuid_generator.dart';
import '../../decks/application/deck_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';
import '../../flashcards/data/flashcard_repository.dart';
import '../../stats/application/stats_controller.dart';
import '../data/review_repository.dart';
import '../domain/sm2_scheduler.dart';
import '../domain/study_session_model.dart';

class StudyController extends Notifier<StudySessionData?> {
  late FlashcardRepository _flashcardRepo;
  late ReviewRepository _reviewRepo;

  /// Cache of idempotency key per card ID to ensure retries use the identical key.
  final Map<String, String> _idempotencyKeys = {};

  @override
  StudySessionData? build() {
    _flashcardRepo = ref.watch(flashcardRepositoryProvider);
    _reviewRepo = ref.watch(reviewRepositoryProvider);
    return null;
  }

  /// Initializes a study session for 1 deck with a hard limit of 20 cards.
  /// Follows Single-Queue query rule: `next_review_at <= now() ORDER BY next_review_at ASC LIMIT 20`.
  Future<void> startSession(String deckId) async {
    state = StudySessionData(
      deckId: deckId,
      deckTitle: 'Memuat...',
      queue: const [],
      state: StudySessionState.loading,
    );

    final deck = ref.read(deckControllerProvider.notifier).getDeckById(deckId);
    final deckTitle = deck?.title ?? 'Sesi Belajar';

    // 1. Single-queue query: LIMIT 20 due cards (including new cards with next_review_at = now())
    final dueQueue = await _flashcardRepo.getDueCardsForDeck(deckId, limit: 20);

    if (dueQueue.isEmpty) {
      // 2. If no due cards, load all cards from deck up to 20 for practice review
      final allCards = await _flashcardRepo.getCardsForDeck(deckId);
      final practiceCards = allCards.take(20).toList();

      if (practiceCards.isEmpty) {
        state = StudySessionData(
          deckId: deckId,
          deckTitle: deckTitle,
          queue: const [],
          state: StudySessionState.empty,
        );
        return;
      }

      state = StudySessionData(
        deckId: deckId,
        deckTitle: deckTitle,
        queue: practiceCards,
        state: StudySessionState.question,
      );
      return;
    }

    state = StudySessionData(
      deckId: deckId,
      deckTitle: deckTitle,
      queue: dueQueue,
      state: StudySessionState.question,
    );
  }

  void revealAnswer() {
    if (state == null) return;
    state = state!.copyWith(state: StudySessionState.answer);
  }

  /// Submits rating for current card via pure Dart SM-2 calculation and atomic RPC.
  /// Returns `true` if advanced to next card, `false` if completed or failed.
  Future<bool> submitRating(int rating) async {
    if (state == null || state!.currentCard == null) return false;

    final card = state!.currentCard!;
    state = state!.copyWith(state: StudySessionState.saving);

    // Calculate next SM-2 schedule state using pure Dart domain scheduler
    final now = DateTime.now().toUtc();
    final schedule = Sm2Scheduler.calculateNextSchedule(
      currentRepetitions: card.repetitions,
      currentIntervalDays: card.intervalDays,
      currentEaseFactor: card.easeFactor,
      quality: rating,
      reviewedAt: now,
    );

    // Retrieve or generate persistent idempotency key for this card review attempt
    final idempotencyKey = _idempotencyKeys.putIfAbsent(
      card.id,
      () => UuidGenerator.v4(),
    );

    try {
      // Atomic RPC call: verifies card ownership & expected_updated_at concurrency token
      await _reviewRepo.submitReview(
        flashcardId: card.id,
        quality: rating,
        repetitions: schedule.repetitions,
        intervalDays: schedule.intervalDays,
        easeFactor: schedule.easeFactor,
        reviewedAt: now,
        nextReviewAt: schedule.nextReviewAt,
        idempotencyKey: idempotencyKey,
        expectedUpdatedAt: card.updatedAt,
      );

      // Clean up key on successful submit
      _idempotencyKeys.remove(card.id);

      // Refresh flashcards and stats state
      ref.read(flashcardControllerProvider.notifier).refresh();
      ref.invalidate(statsControllerProvider);

      // Update session metrics
      final updatedRatings = Map<int, int>.from(state!.ratingCounts);
      updatedRatings[rating] = (updatedRatings[rating] ?? 0) + 1;
      final newReviewedCount = state!.totalReviewedInSession + 1;

      if (state!.currentIndex + 1 < state!.queue.length) {
        state = state!.copyWith(
          currentIndex: state!.currentIndex + 1,
          state: StudySessionState.question,
          ratingCounts: updatedRatings,
          totalReviewedInSession: newReviewedCount,
        );
        return true;
      } else {
        state = state!.copyWith(
          state: StudySessionState.completed,
          ratingCounts: updatedRatings,
          totalReviewedInSession: newReviewedCount,
        );
        return false;
      }
    } catch (e) {
      // On failure, stay on answer screen so user can retry with the same idempotency key
      state = state!.copyWith(state: StudySessionState.answer);
      rethrow;
    }
  }
}

final studyControllerProvider =
    NotifierProvider<StudyController, StudySessionData?>(StudyController.new);
