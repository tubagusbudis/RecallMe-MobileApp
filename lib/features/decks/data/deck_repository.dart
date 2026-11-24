import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/deck_model.dart';

/// Contract for Deck data operations.
abstract class DeckRepository {
  /// Returns all decks for the current user, ordered by updated_at DESC.
  Future<List<DeckModel>> listDecks();

  /// Returns a single deck by [id], or null if not found.
  Future<DeckModel?> getDeckById(String id);

  /// Creates a new deck and returns the created model.
  Future<DeckModel> createDeck({required String title, String description});

  /// Updates an existing deck and returns the updated model.
  Future<DeckModel?> updateDeck({
    required String deckId,
    required String title,
    String description,
  });

  /// Deletes a deck by [id]. ON DELETE CASCADE removes flashcards and review_logs.
  Future<void> deleteDeck(String id);

  /// Maps Supabase/network errors to user-friendly Indonesian messages.
  String mapError(Object error);
}

/// Supabase implementation of [DeckRepository].
class SupabaseDeckRepository implements DeckRepository {
  final SupabaseClient _client;

  SupabaseDeckRepository(this._client);

  @override
  Future<List<DeckModel>> listDecks() async {
    if (_client.auth.currentSession == null) {
      return const [];
    }
    final rows = await _client
        .from('decks')
        .select('id, user_id, title, description, created_at, updated_at')
        .order('updated_at', ascending: false);

    return (rows as List).map((row) {
      return DeckModel.fromMap(row as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<DeckModel?> getDeckById(String id) async {
    if (_client.auth.currentSession == null) {
      return null;
    }
    final row = await _client
        .from('decks')
        .select('id, user_id, title, description, created_at, updated_at')
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return DeckModel.fromMap(row);
  }

  @override
  Future<DeckModel> createDeck({
    required String title,
    String description = '',
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final userId = session.user.id;
    final row = await _client
        .from('decks')
        .insert({
          'user_id': userId,
          'title': title.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
        })
        .select()
        .single();

    return DeckModel.fromMap(row);
  }

  @override
  Future<DeckModel?> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) async {
    if (_client.auth.currentSession == null) {
      throw const AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final row = await _client
        .from('decks')
        .update({
          'title': title.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
        })
        .eq('id', deckId)
        .select()
        .maybeSingle();

    if (row == null) return null;
    return DeckModel.fromMap(row);
  }

  @override
  Future<void> deleteDeck(String id) async {
    if (_client.auth.currentSession == null) {
      return;
    }
    await _client.from('decks').delete().eq('id', id);
  }

  @override
  String mapError(Object error) {
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        return 'Deck dengan judul tersebut sudah ada.';
      }
      if (msg.contains('not_found') || msg.contains('no rows')) {
        return 'Deck tidak ditemukan.';
      }
      return 'Gagal memproses data: ${error.message}';
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

/// In-memory mock implementation for tests and offline preview.
class MockDeckRepository implements DeckRepository {
  final List<DeckModel> _decks = [
    DeckModel(
      id: 'deck-1',
      userId: 'user-1',
      title: 'Flutter & Dart Concepts',
      description: 'Konsep penting Flutter, state management Riverpod, dan Dart fundamentals.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DeckModel(
      id: 'deck-2',
      userId: 'user-1',
      title: 'Kosakata Bahasa Jepang N5',
      description:
          'Kanji dan kosakata dasar JLPT N5 untuk percakapan sehari-hari.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DeckModel(
      id: 'deck-3',
      userId: 'user-1',
      title: 'Basis Data & SQL',
      description: 'Indeks relasional, Row Level Security (RLS), transaksi atomik, dan CASCADE.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<DeckModel>> listDecks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_decks);
  }

  @override
  Future<DeckModel?> getDeckById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _decks.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DeckModel> createDeck({
    required String title,
    String description = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final deck = DeckModel(
      id: 'deck-${now.millisecondsSinceEpoch}',
      userId: 'user-1',
      title: title.trim(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _decks.insert(0, deck);
    return deck;
  }

  @override
  Future<DeckModel?> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index == -1) return null;
    final updated = _decks[index].copyWith(
      title: title.trim(),
      description: description.trim(),
      updatedAt: DateTime.now(),
    );
    _decks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteDeck(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _decks.removeWhere((d) => d.id == id);
  }

  @override
  String mapError(Object error) => error.toString();
}

/// Provider for [DeckRepository]. Auto-selects implementation based on
/// whether Supabase is configured via `--dart-define`.
final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseDeckRepository(SupabaseConfig.client);
  }
  debugPrint(
    '⚠️ [DeckRepository] Using MockDeckRepository (Supabase not configured)',
  );
  return MockDeckRepository();
});
