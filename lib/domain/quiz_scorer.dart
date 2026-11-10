import '../data/models/quiz_model.dart';

class QuizScorer {
  /// Evaluates and scores a single question
  static int scoreQuestion({
    required QuizQuestionModel question,
    required dynamic selectedAnswer,
  }) {
    if (question.correctIndexes.isEmpty && question.type != QuestionType.shortAnswer && question.type != QuestionType.longAnswer) {
      return 0; // Empty correctIndexes never awards marks
    }

    if (question.type == QuestionType.mcq || question.type == QuestionType.trueFalse) {
      final int selected = (selectedAnswer is List && selectedAnswer.isNotEmpty)
          ? (selectedAnswer.first as int)
          : (selectedAnswer is int ? selectedAnswer : -1);

      if (question.correctIndexes.contains(selected)) {
        return question.marks;
      }
      return 0;
    }

    if (question.type == QuestionType.multiSelect) {
      final List<int> selectedList = (selectedAnswer is List)
          ? List<int>.from(selectedAnswer.map((e) => (e as num).toInt()))
          : [];

      final Set<int> selectedSet = selectedList.toSet();
      final Set<int> correctSet = question.correctIndexes.toSet();

      // Multi-select requires exact set match for full marks, partial match = 0
      if (selectedSet.length == correctSet.length && selectedSet.containsAll(correctSet)) {
        return question.marks;
      }
      return 0;
    }

    return 0;
  }

  /// Maps selected indexes in a shuffled options list back to original option indexes
  static List<int> mapShuffledIndexesToOriginal({
    required List<int> selectedShuffledIndexes,
    required List<int> shuffledToOriginalMap,
  }) {
    return selectedShuffledIndexes
        .where((sIdx) => sIdx >= 0 && sIdx < shuffledToOriginalMap.length)
        .map((sIdx) => shuffledToOriginalMap[sIdx])
        .toList();
  }
}
