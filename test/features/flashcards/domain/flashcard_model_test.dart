import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/flashcards/domain/flashcard_model.dart';

void main() {
  group('FlashcardModel tests', () {
    test('fromMap parses Supabase row map accurately', () {
      final map = {
        'id': 'f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c',
        'deck_id': 'd1b9b940-1e5b-4c12-b924-f5a6b0c1d2e3',
        'question': 'Apa itu mitokondria?',
        'answer': 'Organel penghasil ATP (energi sel)',
        'repetitions': 3,
        'interval_days': 6,
        'ease_factor': 2.500,
        'next_review_at': '2026-11-28T07:00:00.000Z',
        'last_review_at': '2026-11-22T07:00:00.000Z',
        'created_at': '2026-11-20T07:00:00.000Z',
        'updated_at': '2026-11-22T07:00:00.000Z',
      };

      final card = FlashcardModel.fromMap(map);

      expect(card.id, 'f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c');
      expect(card.deckId, 'd1b9b940-1e5b-4c12-b924-f5a6b0c1d2e3');
      expect(card.question, 'Apa itu mitokondria?');
      expect(card.answer, 'Organel penghasil ATP (energi sel)');
      expect(card.repetitions, 3);
      expect(card.intervalDays, 6);
      expect(card.easeFactor, 2.5);
      expect(card.nextReviewAt, DateTime.parse('2026-11-28T07:00:00.000Z'));
      expect(card.lastReviewAt, DateTime.parse('2026-11-22T07:00:00.000Z'));
      expect(card.isNew, isFalse);
    });

    test('isNew is true when repetitions == 0 and lastReviewAt is null', () {
      final card = FlashcardModel(
        id: 'card-new',
        deckId: 'deck-1',
        question: 'Pertanyaan baru',
        answer: 'Jawaban baru',
        repetitions: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewAt: DateTime.now(),
        lastReviewAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(card.isNew, isTrue);
      expect(card.isDue, isTrue); // nextReviewAt is now
    });

    test('toInsertMap includes only deck_id, question, and answer', () {
      final card = FlashcardModel(
        id: 'temp-id',
        deckId: 'deck-101',
        question: '  Apa itu RLS?  ',
        answer: '  Row Level Security  ',
        nextReviewAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final insertMap = card.toInsertMap();

      expect(insertMap['deck_id'], 'deck-101');
      expect(insertMap['question'], 'Apa itu RLS?');
      expect(insertMap['answer'], 'Row Level Security');
      // Scheduling fields must NOT be in insert map (handled by database defaults)
      expect(insertMap.containsKey('repetitions'), isFalse);
      expect(insertMap.containsKey('interval_days'), isFalse);
      expect(insertMap.containsKey('ease_factor'), isFalse);
      expect(insertMap.containsKey('next_review_at'), isFalse);
    });

    test('toUpdateMap includes only question and answer', () {
      final card = FlashcardModel(
        id: 'card-101',
        deckId: 'deck-101',
        question: 'Updated Question',
        answer: 'Updated Answer',
        repetitions: 5,
        intervalDays: 14,
        easeFactor: 2.7,
        nextReviewAt: DateTime.now().add(const Duration(days: 14)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateMap = card.toUpdateMap();

      expect(updateMap['question'], 'Updated Question');
      expect(updateMap['answer'], 'Updated Answer');
      expect(updateMap.containsKey('repetitions'), isFalse);
      expect(updateMap.containsKey('interval_days'), isFalse);
      expect(updateMap.containsKey('deck_id'), isFalse);
    });
  });
}
