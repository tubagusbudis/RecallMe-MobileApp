import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/flashcards/data/flashcard_repository.dart';

void main() {
  group('MockFlashcardRepository CRUD tests', () {
    late MockFlashcardRepository repo;

    setUp(() {
      repo = MockFlashcardRepository();
    });

    test('listAllCards returns initial cards across decks', () async {
      final cards = await repo.listAllCards();
      expect(cards.length, 8);
    });

    test('getCardsForDeck returns only cards for that deck', () async {
      final deck1Cards = await repo.getCardsForDeck('deck-1');
      expect(deck1Cards.length, 4);
      expect(deck1Cards.every((c) => c.deckId == 'deck-1'), isTrue);

      final deck2Cards = await repo.getCardsForDeck('deck-2');
      expect(deck2Cards.length, 3);
    });

    test(
      'getDueCardsForDeck returns due cards ordered by nextReviewAt',
      () async {
        final dueCards = await repo.getDueCardsForDeck('deck-1', limit: 20);
        expect(dueCards.isNotEmpty, isTrue);
        expect(dueCards.length, lessThanOrEqualTo(4));
        // Verify ordering
        for (int i = 0; i < dueCards.length - 1; i++) {
          expect(
            dueCards[i].nextReviewAt.isBefore(dueCards[i + 1].nextReviewAt) ||
                dueCards[i].nextReviewAt.isAtSameMomentAs(
                  dueCards[i + 1].nextReviewAt,
                ),
            isTrue,
          );
        }
      },
    );

    test('createCard adds new card with default scheduling', () async {
      final created = await repo.createCard(
        deckId: 'deck-1',
        question: 'Apa itu Isolate?',
        answer: 'Unit eksekusi thread terisolasi di Dart',
      );

      expect(created.deckId, 'deck-1');
      expect(created.question, 'Apa itu Isolate?');
      expect(created.answer, 'Unit eksekusi thread terisolasi di Dart');
      expect(created.repetitions, 0);
      expect(created.intervalDays, 0);
      expect(created.easeFactor, 2.5);
      expect(created.isNew, isTrue);

      final deckCards = await repo.getCardsForDeck('deck-1');
      expect(deckCards.length, 5);
    });

    test(
      'updateCard updates question and answer without altering schedule',
      () async {
        final updated = await repo.updateCard(
          cardId: 'card-1',
          question: 'Pertanyaan baru?',
          answer: 'Jawaban baru.',
        );

        expect(updated, isNotNull);
        expect(updated!.question, 'Pertanyaan baru?');
        expect(updated.answer, 'Jawaban baru.');
        // Scheduling fields remain intact
        expect(updated.repetitions, 2);
        expect(updated.intervalDays, 3);
        expect(updated.easeFactor, 2.5);
      },
    );

    test('deleteCard removes card from deck', () async {
      await repo.deleteCard('card-1');

      final card = await repo.getCardById('card-1');
      expect(card, isNull);

      final count = await repo.getCardCountForDeck('deck-1');
      expect(count, 3);
    });

    test('counts are reported correctly', () async {
      final deck1Count = await repo.getCardCountForDeck('deck-1');
      expect(deck1Count, 4);

      final totalDue = await repo.getTotalDueCount();
      expect(totalDue, greaterThan(0));
    });
  });
}
