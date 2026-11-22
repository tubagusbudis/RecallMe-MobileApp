import '../../flashcards/domain/flashcard_model.dart';

enum StudySessionState { loading, empty, question, answer, saving, completed }

class StudySessionData {
  final String deckId;
  final String deckTitle;
  final List<FlashcardModel> queue;
  final int currentIndex;
  final StudySessionState state;
  final Map<int, int> ratingCounts; // rating (1,3,4,5) -> count
  final int totalReviewedInSession;

  const StudySessionData({
    required this.deckId,
    required this.deckTitle,
    required this.queue,
    this.currentIndex = 0,
    this.state = StudySessionState.question,
    this.ratingCounts = const {1: 0, 3: 0, 4: 0, 5: 0},
    this.totalReviewedInSession = 0,
  });

  FlashcardModel? get currentCard {
    if (currentIndex >= 0 && currentIndex < queue.length) {
      return queue[currentIndex];
    }
    return null;
  }

  int get totalCards => queue.length;
  int get currentProgressNumber => currentIndex + 1;

  StudySessionData copyWith({
    String? deckId,
    String? deckTitle,
    List<FlashcardModel>? queue,
    int? currentIndex,
    StudySessionState? state,
    Map<int, int>? ratingCounts,
    int? totalReviewedInSession,
  }) {
    return StudySessionData(
      deckId: deckId ?? this.deckId,
      deckTitle: deckTitle ?? this.deckTitle,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      state: state ?? this.state,
      ratingCounts: ratingCounts ?? this.ratingCounts,
      totalReviewedInSession:
          totalReviewedInSession ?? this.totalReviewedInSession,
    );
  }
}
