import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/decks/data/deck_repository.dart';

void main() {
  group('MockDeckRepository CRUD tests', () {
    late MockDeckRepository repo;

    setUp(() {
      repo = MockDeckRepository();
    });

    test('listDecks returns initial mock decks', () async {
      final decks = await repo.listDecks();
      expect(decks.length, 3);
      expect(decks[0].title, 'Flutter & Dart Concepts');
    });

    test('getDeckById returns correct deck or null if missing', () async {
      final deck = await repo.getDeckById('deck-1');
      expect(deck, isNotNull);
      expect(deck!.title, 'Flutter & Dart Concepts');

      final missing = await repo.getDeckById('non-existent');
      expect(missing, isNull);
    });

    test('createDeck prepends new deck', () async {
      final created = await repo.createDeck(
        title: 'Algoritma Pemrograman',
        description: 'Sorting, searching, dan dynamic programming',
      );

      expect(created.title, 'Algoritma Pemrograman');
      expect(
        created.description,
        'Sorting, searching, dan dynamic programming',
      );

      final decks = await repo.listDecks();
      expect(decks.length, 4);
      expect(decks.first.title, 'Algoritma Pemrograman');
    });

    test('updateDeck modifies title and description', () async {
      final updated = await repo.updateDeck(
        deckId: 'deck-1',
        title: 'Flutter Advanced',
        description: 'Custom painters & shaders',
      );

      expect(updated, isNotNull);
      expect(updated!.title, 'Flutter Advanced');
      expect(updated.description, 'Custom painters & shaders');

      final deck = await repo.getDeckById('deck-1');
      expect(deck!.title, 'Flutter Advanced');
    });

    test('deleteDeck removes deck from repository', () async {
      await repo.deleteDeck('deck-2');

      final decks = await repo.listDecks();
      expect(decks.length, 2);
      expect(decks.any((d) => d.id == 'deck-2'), isFalse);
    });
  });
}
