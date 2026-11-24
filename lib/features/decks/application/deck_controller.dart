import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/deck_repository.dart';
import '../domain/deck_model.dart';

/// Async controller for deck CRUD operations via [DeckRepository].
class DeckController extends AsyncNotifier<List<DeckModel>> {
  late DeckRepository _repository;

  @override
  Future<List<DeckModel>> build() async {
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    if (userId == null) {
      return const [];
    }
    _repository = ref.watch(deckRepositoryProvider);
    return _repository.listDecks();
  }

  /// Reloads the deck list from the repository.
  Future<void> refresh() async {
    final userId = ref.read(authControllerProvider.select((s) => s.user?.id));
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.listDecks());
  }

  /// Creates a new deck and prepends it to the list.
  Future<DeckModel> addDeck({
    required String title,
    String description = '',
  }) async {
    final deck = await _repository.createDeck(
      title: title,
      description: description,
    );
    final current = state.value ?? [];
    state = AsyncValue.data([deck, ...current]);
    return deck;
  }

  /// Updates an existing deck's title and description.
  Future<void> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) async {
    final updated = await _repository.updateDeck(
      deckId: deckId,
      title: title,
      description: description,
    );
    if (updated != null) {
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((d) => d.id == deckId ? updated : d).toList(),
      );
    }
  }

  /// Deletes a deck. ON DELETE CASCADE removes flashcards and review_logs in DB.
  Future<void> deleteDeck(String deckId) async {
    await _repository.deleteDeck(deckId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((d) => d.id != deckId).toList());
  }

  /// Returns a deck by ID from the current in-memory state.
  DeckModel? getDeckById(String deckId) {
    final decks = state.value;
    if (decks == null) return null;
    try {
      return decks.firstWhere((d) => d.id == deckId);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: error mapper from repository.
  String mapError(Object error) => _repository.mapError(error);
}

final deckControllerProvider =
    AsyncNotifierProvider<DeckController, List<DeckModel>>(DeckController.new);
