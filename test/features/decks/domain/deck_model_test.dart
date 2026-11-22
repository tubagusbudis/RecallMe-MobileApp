import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/decks/domain/deck_model.dart';

void main() {
  group('DeckModel tests', () {
    test('fromMap parses Supabase row map accurately', () {
      final map = {
        'id': 'd1b9b940-1e5b-4c12-b924-f5a6b0c1d2e3',
        'user_id': 'u1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c',
        'title': 'Biologi Sel',
        'description': 'Struktur membran dan organel',
        'created_at': '2026-11-22T08:00:00.000Z',
        'updated_at': '2026-11-22T09:30:00.000Z',
      };

      final deck = DeckModel.fromMap(map);

      expect(deck.id, 'd1b9b940-1e5b-4c12-b924-f5a6b0c1d2e3');
      expect(deck.userId, 'u1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c');
      expect(deck.title, 'Biologi Sel');
      expect(deck.description, 'Struktur membran dan organel');
      expect(deck.createdAt, DateTime.parse('2026-11-22T08:00:00.000Z'));
      expect(deck.updatedAt, DateTime.parse('2026-11-22T09:30:00.000Z'));
    });

    test('fromMap handles null description gracefully', () {
      final map = {
        'id': 'deck-123',
        'user_id': 'user-123',
        'title': 'Fisika Dasar',
        'description': null,
        'created_at': '2026-11-22T08:00:00.000Z',
        'updated_at': '2026-11-22T08:00:00.000Z',
      };

      final deck = DeckModel.fromMap(map);
      expect(deck.description, '');
    });

    test('toInsertMap trims title and description and includes userId', () {
      final deck = DeckModel(
        id: 'temp-id',
        userId: 'user-456',
        title: '  Matematika Diskrit  ',
        description: '  Teori Graf & Himpunan  ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final insertMap = deck.toInsertMap();

      expect(insertMap['user_id'], 'user-456');
      expect(insertMap['title'], 'Matematika Diskrit');
      expect(insertMap['description'], 'Teori Graf & Himpunan');
    });

    test('toInsertMap sets description to null when empty', () {
      final deck = DeckModel(
        id: 'temp-id',
        userId: 'user-456',
        title: 'Kalkulus',
        description: '   ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final insertMap = deck.toInsertMap();
      expect(insertMap['description'], isNull);
    });

    test('toUpdateMap contains only title and description', () {
      final deck = DeckModel(
        id: 'deck-789',
        userId: 'user-456',
        title: 'Kimia Organik',
        description: 'Reaksi substitusi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateMap = deck.toUpdateMap();

      expect(updateMap.containsKey('user_id'), isFalse);
      expect(updateMap.containsKey('id'), isFalse);
      expect(updateMap['title'], 'Kimia Organik');
      expect(updateMap['description'], 'Reaksi substitusi');
    });

    test('deckColorFromId is deterministic', () {
      final color1 = deckColorFromId('deck-abc');
      final color2 = deckColorFromId('deck-abc');
      expect(color1, equals(color2));
    });
  });
}
