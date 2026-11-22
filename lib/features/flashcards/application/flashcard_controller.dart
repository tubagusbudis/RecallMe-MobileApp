import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/flashcard_repository.dart';
import '../domain/flashcard_model.dart';

/// Async controller for flashcard operations across decks.
class FlashcardController extends AsyncNotifier<List<FlashcardModel>> {
  late FlashcardRepository _repository;

  @override
  Future<List<FlashcardModel>> build() async {
    _repository = ref.watch(flashcardRepositoryProvider);
    return _repository.listAllCards();
  }

  /// Reloads all flashcards from repository.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.listAllCards());
  }

  /// Synchronous helper: returns cards from memory for a given deck.
  List<FlashcardModel> getCardsForDeck(String deckId) {
    return (state.value ?? []).where((c) => c.deckId == deckId).toList();
  }

  /// Synchronous helper: returns due cards for a deck from memory.
  List<FlashcardModel> getDueCardsForDeck(String deckId, {int limit = 20}) {
    final now = DateTime.now();
    final deckCards =
        (state.value ?? [])
            .where(
              (c) =>
                  c.deckId == deckId &&
                  (c.nextReviewAt.isBefore(now) ||
                      c.nextReviewAt.isAtSameMomentAs(now)),
            )
            .toList()
          ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return deckCards.take(limit).toList();
  }

  /// Synchronous helper: returns due count for a deck from memory.
  int getDueCountForDeck(String deckId) {
    final now = DateTime.now();
    return (state.value ?? [])
        .where(
          (c) =>
              c.deckId == deckId &&
              (c.nextReviewAt.isBefore(now) ||
                  c.nextReviewAt.isAtSameMomentAs(now)),
        )
        .length;
  }

  /// Synchronous helper: returns total due count across all decks.
  int getTotalDueCount() {
    final now = DateTime.now();
    return (state.value ?? [])
        .where(
          (c) =>
              c.nextReviewAt.isBefore(now) ||
              c.nextReviewAt.isAtSameMomentAs(now),
        )
        .length;
  }

  /// Synchronous helper: returns a card by ID from memory.
  FlashcardModel? getCardById(String cardId) {
    try {
      return (state.value ?? []).firstWhere((c) => c.id == cardId);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new flashcard in DB and appends to local state.
  /// New card defaults to next_review_at = now() via DB default.
  Future<FlashcardModel> addCard({
    required String deckId,
    required String question,
    required String answer,
  }) async {
    final card = await _repository.createCard(
      deckId: deckId,
      question: question,
      answer: answer,
    );
    final current = state.value ?? [];
    state = AsyncValue.data([...current, card]);
    return card;
  }

  /// Updates flashcard question & answer in DB and local state.
  Future<void> updateCard({
    required String cardId,
    required String question,
    required String answer,
  }) async {
    final updated = await _repository.updateCard(
      cardId: cardId,
      question: question,
      answer: answer,
    );
    if (updated != null) {
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((c) => c.id == cardId ? updated : c).toList(),
      );
    }
  }

  /// Deletes a flashcard in DB and removes from local state.
  Future<void> deleteCard(String cardId) async {
    await _repository.deleteCard(cardId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((c) => c.id != cardId).toList());
  }

  /// Removes cards belonging to deleted deck from local state.
  void deleteCardsByDeckId(String deckId) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((c) => c.deckId != deckId).toList());
  }

  /// Update scheduling after study review (temporary mock SM-2 logic).
  /// Replaced by Sm2Scheduler + RPC in Phase 5.
  void updateScheduleAfterReview({
    required String cardId,
    required int rating, // 1=Again, 3=Hard, 4=Good, 5=Easy
  }) {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((c) {
        if (c.id == cardId) {
          int nextRepetitions = c.repetitions;
          int nextInterval = c.intervalDays;
          double nextEase = c.easeFactor;
          final now = DateTime.now();

          if (rating == 1) {
            nextRepetitions = 0;
            nextInterval = 1;
            nextEase = (nextEase - 0.2).clamp(1.3, 3.0);
          } else if (rating == 3) {
            nextRepetitions += 1;
            nextInterval = (nextInterval * 1.2).ceil().clamp(1, 365);
            nextEase = (nextEase - 0.15).clamp(1.3, 3.0);
          } else if (rating == 4) {
            if (nextRepetitions == 0) {
              nextInterval = 1;
            } else if (nextRepetitions == 1) {
              nextInterval = 6;
            } else {
              nextInterval = (nextInterval * nextEase).round();
            }
            nextRepetitions += 1;
          } else if (rating == 5) {
            if (nextRepetitions == 0) {
              nextInterval = 4;
            } else if (nextRepetitions == 1) {
              nextInterval = 10;
            } else {
              nextInterval = (nextInterval * nextEase * 1.3).round();
            }
            nextRepetitions += 1;
            nextEase = (nextEase + 0.15).clamp(1.3, 3.0);
          }

          final nextReview = now.add(Duration(days: nextInterval));

          return c.copyWith(
            repetitions: nextRepetitions,
            intervalDays: nextInterval,
            easeFactor: nextEase,
            nextReviewAt: nextReview,
            lastReviewAt: now,
            updatedAt: now,
          );
        }
        return c;
      }).toList(),
    );
  }

  /// Convenience: error mapper from repository.
  String mapError(Object error) => _repository.mapError(error);
}

final flashcardControllerProvider =
    AsyncNotifierProvider<FlashcardController, List<FlashcardModel>>(
      FlashcardController.new,
    );
