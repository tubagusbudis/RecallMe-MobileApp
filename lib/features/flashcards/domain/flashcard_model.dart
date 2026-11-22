class FlashcardModel {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewAt;
  final DateTime? lastReviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    required this.nextReviewAt,
    this.lastReviewAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDue =>
      nextReviewAt.isBefore(DateTime.now().add(const Duration(minutes: 1)));
  bool get isNew => repetitions == 0 && lastReviewAt == null;

  /// Creates a [FlashcardModel] from a Supabase row map.
  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      repetitions: (map['repetitions'] as num).toInt(),
      intervalDays: (map['interval_days'] as num).toInt(),
      easeFactor: (map['ease_factor'] as num).toDouble(),
      nextReviewAt: DateTime.parse(map['next_review_at'] as String),
      lastReviewAt: map['last_review_at'] != null
          ? DateTime.parse(map['last_review_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Map for inserting a new flashcard. Only sends deck_id, question, answer.
  /// Database handles defaults: repetitions=0, interval_days=0,
  /// ease_factor=2.5, next_review_at=now(), last_review_at=NULL.
  Map<String, dynamic> toInsertMap() {
    return {
      'deck_id': deckId,
      'question': question.trim(),
      'answer': answer.trim(),
    };
  }

  /// Map for updating flashcard text only.
  /// Editing question/answer does NOT reset scheduling fields or review history.
  Map<String, dynamic> toUpdateMap() {
    return {'question': question.trim(), 'answer': answer.trim()};
  }

  FlashcardModel copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    int? repetitions,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewAt,
    DateTime? lastReviewAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
