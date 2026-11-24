import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/flashcard_model.dart';

/// Contract for Flashcard data operations.
abstract class FlashcardRepository {
  /// Returns all cards owned by the authenticated user across all decks.
  Future<List<FlashcardModel>> listAllCards();

  /// Returns all cards in a deck, ordered by created_at ASC.
  Future<List<FlashcardModel>> getCardsForDeck(String deckId);

  /// Returns a single card by [id], or null if not found.
  Future<FlashcardModel?> getCardById(String id);

  /// Returns due cards for a deck: next_review_at <= now(),
  /// ordered by next_review_at ASC, limited to [limit] cards.
  Future<List<FlashcardModel>> getDueCardsForDeck(
    String deckId, {
    int limit = 20,
  });

  /// Creates a new flashcard. DB handles scheduling defaults.
  Future<FlashcardModel> createCard({
    required String deckId,
    required String question,
    required String answer,
  });

  /// Updates flashcard text only (question/answer).
  /// Does NOT reset scheduling fields.
  Future<FlashcardModel?> updateCard({
    required String cardId,
    required String question,
    required String answer,
  });

  /// Deletes a flashcard. ON DELETE CASCADE removes review_logs.
  Future<void> deleteCard(String id);

  /// Returns total card count for a deck.
  Future<int> getCardCountForDeck(String deckId);

  /// Returns count of due cards for a deck (next_review_at <= now()).
  Future<int> getDueCountForDeck(String deckId);

  /// Returns total due card count across all decks for the current user.
  Future<int> getTotalDueCount();

  /// Maps errors to user-friendly Indonesian messages.
  String mapError(Object error);
}

const _selectColumns =
    'id, deck_id, question, answer, repetitions, '
    'interval_days, ease_factor, next_review_at, '
    'last_review_at, created_at, updated_at';

/// Supabase implementation of [FlashcardRepository].
class SupabaseFlashcardRepository implements FlashcardRepository {
  final SupabaseClient _client;

  SupabaseFlashcardRepository(this._client);

  @override
  Future<List<FlashcardModel>> listAllCards() async {
    if (_client.auth.currentSession == null) {
      return const [];
    }
    final rows = await _client
        .from('flashcards')
        .select(_selectColumns)
        .order('created_at');

    return (rows as List)
        .map((row) => FlashcardModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FlashcardModel>> getCardsForDeck(String deckId) async {
    if (_client.auth.currentSession == null) {
      return const [];
    }
    final rows = await _client
        .from('flashcards')
        .select(_selectColumns)
        .eq('deck_id', deckId)
        .order('created_at');

    return (rows as List)
        .map((row) => FlashcardModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FlashcardModel?> getCardById(String id) async {
    if (_client.auth.currentSession == null) {
      return null;
    }
    final row = await _client
        .from('flashcards')
        .select(_selectColumns)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return FlashcardModel.fromMap(row);
  }

  @override
  Future<List<FlashcardModel>> getDueCardsForDeck(
    String deckId, {
    int limit = 20,
  }) async {
    if (_client.auth.currentSession == null) {
      return const [];
    }
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('flashcards')
        .select(_selectColumns)
        .eq('deck_id', deckId)
        .lte('next_review_at', nowUtc)
        .order('next_review_at', ascending: true)
        .limit(limit);

    return (rows as List)
        .map((row) => FlashcardModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FlashcardModel> createCard({
    required String deckId,
    required String question,
    required String answer,
  }) async {
    if (_client.auth.currentSession == null) {
      throw const AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final row = await _client
        .from('flashcards')
        .insert({
          'deck_id': deckId,
          'question': question.trim(),
          'answer': answer.trim(),
        })
        .select()
        .single();

    return FlashcardModel.fromMap(row);
  }

  @override
  Future<FlashcardModel?> updateCard({
    required String cardId,
    required String question,
    required String answer,
  }) async {
    if (_client.auth.currentSession == null) {
      throw const AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final row = await _client
        .from('flashcards')
        .update({'question': question.trim(), 'answer': answer.trim()})
        .eq('id', cardId)
        .select()
        .maybeSingle();

    if (row == null) return null;
    return FlashcardModel.fromMap(row);
  }

  @override
  Future<void> deleteCard(String id) async {
    if (_client.auth.currentSession == null) {
      return;
    }
    await _client.from('flashcards').delete().eq('id', id);
  }

  @override
  Future<int> getCardCountForDeck(String deckId) async {
    if (_client.auth.currentSession == null) {
      return 0;
    }
    final response = await _client
        .from('flashcards')
        .select('id')
        .eq('deck_id', deckId)
        .count(CountOption.exact);
    return response.count;
  }

  @override
  Future<int> getDueCountForDeck(String deckId) async {
    if (_client.auth.currentSession == null) {
      return 0;
    }
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('flashcards')
        .select('id')
        .eq('deck_id', deckId)
        .lte('next_review_at', nowUtc)
        .count(CountOption.exact);
    return response.count;
  }

  @override
  Future<int> getTotalDueCount() async {
    if (_client.auth.currentSession == null) {
      return 0;
    }
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('flashcards')
        .select('id')
        .lte('next_review_at', nowUtc)
        .count(CountOption.exact);
    return response.count;
  }

  @override
  String mapError(Object error) {
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('not_found') || msg.contains('no rows')) {
        return 'Flashcard tidak ditemukan.';
      }
      if (msg.contains('check') && msg.contains('not_empty')) {
        return 'Pertanyaan dan jawaban tidak boleh kosong.';
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
class MockFlashcardRepository implements FlashcardRepository {
  final List<FlashcardModel> _cards = [
    // deck-1: Flutter & Dart Concepts
    FlashcardModel(
      id: 'card-1',
      deckId: 'deck-1',
      question: 'Apa perbedaan StatelessWidget dan StatefulWidget di Flutter?',
      answer: 'StatelessWidget tidak memiliki mutable state internal dan di-build secara immutable.\n\nStatefulWidget mengikat State object yang mutable dan memicu render ulang saat setState() dipanggil.',
      repetitions: 2,
      intervalDays: 3,
      easeFactor: 2.5,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 4)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FlashcardModel(
      id: 'card-2',
      deckId: 'deck-1',
      question:
          'Bagaimana cara kerja antrean tunggal (Single Queue) pada RecallMe?',
      answer: 'Kartu baru dibuat dengan next_review_at = now() dan repetitions = 0, sehingga langsung otomatis masuk ke antrean belajar deck bersama kartu yang jatuh tempo.',
      repetitions: 0,
      intervalDays: 0,
      easeFactor: 2.5,
      nextReviewAt: DateTime.now().subtract(const Duration(minutes: 10)),
      lastReviewAt: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FlashcardModel(
      id: 'card-3',
      deckId: 'deck-1',
      question:
          'Mengapa penghapusan deck di RecallMe menggunakan ON DELETE CASCADE?',
      answer: 'Menghapus deck secara otomatis menghapus seluruh flashcard dan review_logs terkait di database, menjaga relasi bersih tanpa orphan records dan tanpa kerumitan soft delete.',
      repetitions: 1,
      intervalDays: 1,
      easeFactor: 2.4,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 1)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FlashcardModel(
      id: 'card-4',
      deckId: 'deck-1',
      question: 'Apa fungsi WidgetRef pada ConsumerWidget di Riverpod?',
      answer: 'WidgetRef memungkinkan widget membaca (ref.watch), mendengarkan (ref.listen), atau berinteraksi dengan provider tanpa perlu BuildContext khusus Riverpod.',
      repetitions: 3,
      intervalDays: 6,
      easeFactor: 2.6,
      nextReviewAt: DateTime.now().add(const Duration(days: 4)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    // deck-2: Kosakata Bahasa Jepang N5
    FlashcardModel(
      id: 'card-5',
      deckId: 'deck-2',
      question: 'Apa arti dan cara baca dari kanji: 食べる ?',
      answer: 'Cara baca: たべる (taberu)\nArti: Makan.',
      repetitions: 1,
      intervalDays: 1,
      easeFactor: 2.5,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FlashcardModel(
      id: 'card-6',
      deckId: 'deck-2',
      question: 'Apa arti dan cara baca dari kanji: 飲む ?',
      answer: 'Cara baca: のむ (nomu)\nArti: Minum.',
      repetitions: 0,
      intervalDays: 0,
      easeFactor: 2.5,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 3)),
      lastReviewAt: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FlashcardModel(
      id: 'card-7',
      deckId: 'deck-2',
      question: 'Apa fungsi partikel を (wo/o) dalam tata bahasa Jepang?',
      answer: 'Menandai objek penderita (langsung) dari suatu kata kerja transitif. Contoh: 水を飲む (mizu o nomu = minum air).',
      repetitions: 4,
      intervalDays: 10,
      easeFactor: 2.6,
      nextReviewAt: DateTime.now().add(const Duration(days: 5)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    // deck-3: Basis Data & SQL
    FlashcardModel(
      id: 'card-8',
      deckId: 'deck-3',
      question: 'Apa itu Row Level Security (RLS) di PostgreSQL?',
      answer: 'Fitur keamanan di level database yang membatasi baris data mana saja yang dapat dibaca atau dimodifikasi oleh query pengguna berdasarkan context auth (misal: auth.uid()).',
      repetitions: 2,
      intervalDays: 3,
      easeFactor: 2.5,
      nextReviewAt: DateTime.now().subtract(const Duration(minutes: 30)),
      lastReviewAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<FlashcardModel>> listAllCards() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_cards);
  }

  @override
  Future<List<FlashcardModel>> getCardsForDeck(String deckId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cards.where((c) => c.deckId == deckId).toList();
  }

  @override
  Future<FlashcardModel?> getCardById(String id) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FlashcardModel>> getDueCardsForDeck(
    String deckId, {
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final now = DateTime.now();
    final due =
        _cards
            .where(
              (c) =>
                  c.deckId == deckId &&
                  (c.nextReviewAt.isBefore(now) ||
                      c.nextReviewAt.isAtSameMomentAs(now)),
            )
            .toList()
          ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return due.take(limit).toList();
  }

  @override
  Future<FlashcardModel> createCard({
    required String deckId,
    required String question,
    required String answer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final card = FlashcardModel(
      id: 'card-${now.millisecondsSinceEpoch}',
      deckId: deckId,
      question: question.trim(),
      answer: answer.trim(),
      nextReviewAt: now,
      createdAt: now,
      updatedAt: now,
    );
    _cards.add(card);
    return card;
  }

  @override
  Future<FlashcardModel?> updateCard({
    required String cardId,
    required String question,
    required String answer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index == -1) return null;
    final updated = _cards[index].copyWith(
      question: question.trim(),
      answer: answer.trim(),
      updatedAt: DateTime.now(),
    );
    _cards[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCard(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _cards.removeWhere((c) => c.id == id);
  }

  @override
  Future<int> getCardCountForDeck(String deckId) async {
    return _cards.where((c) => c.deckId == deckId).length;
  }

  @override
  Future<int> getDueCountForDeck(String deckId) async {
    final now = DateTime.now();
    return _cards
        .where(
          (c) =>
              c.deckId == deckId &&
              (c.nextReviewAt.isBefore(now) ||
                  c.nextReviewAt.isAtSameMomentAs(now)),
        )
        .length;
  }

  @override
  Future<int> getTotalDueCount() async {
    final now = DateTime.now();
    return _cards
        .where(
          (c) =>
              c.nextReviewAt.isBefore(now) ||
              c.nextReviewAt.isAtSameMomentAs(now),
        )
        .length;
  }

  @override
  String mapError(Object error) => error.toString();
}

/// Provider for [FlashcardRepository].
final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseFlashcardRepository(SupabaseConfig.client);
  }
  debugPrint(
    '⚠️ [FlashcardRepository] Using MockFlashcardRepository '
    '(Supabase not configured)',
  );
  return MockFlashcardRepository();
});
