import 'dart:math';
import '../data/models/quiz_model.dart';

class ShuffleService {
  static const Set<String> _pinnedPhrases = {
    'all of the above',
    'none of the above',
    'both a and b',
    'both b and c',
    'both a and c',
  };

  static bool isPinnedOption(String optionText) {
    return _pinnedPhrases.contains(optionText.trim().toLowerCase());
  }

  /// Shuffles questions and returns question IDs in displayed order
  static List<String> shuffleQuestions(List<QuizQuestionModel> questions, {Random? random}) {
    final rand = random ?? Random();
    final ids = questions.map((q) => q.id).toList();
    ids.shuffle(rand);
    return ids;
  }

  /// Shuffles question options and returns a list of ORIGINAL option indexes in displayed order
  static List<int> shuffleOptionIndexes(QuizQuestionModel question, {Random? random}) {
    // True/False options are NEVER shuffled
    if (question.type == QuestionType.trueFalse || question.options.length <= 1) {
      return List<int>.generate(question.options.length, (i) => i);
    }

    final rand = random ?? Random();
    final List<int> unpinnedIndexes = [];
    final List<int> pinnedIndexes = [];

    for (int i = 0; i < question.options.length; i++) {
      if (isPinnedOption(question.options[i])) {
        pinnedIndexes.add(i);
      } else {
        unpinnedIndexes.add(i);
      }
    }

    unpinnedIndexes.shuffle(rand);
    return [...unpinnedIndexes, ...pinnedIndexes];
  }
}
