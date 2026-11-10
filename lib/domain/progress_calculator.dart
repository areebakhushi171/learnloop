class ProgressResult {
  final double progressPercent; // 0.0 to 1.0
  final double lessonPercent;   // 0.0 to 1.0
  final double quizPercent;     // 0.0 to 1.0
  final bool isCompleted;

  const ProgressResult({
    required this.progressPercent,
    required this.lessonPercent,
    required this.quizPercent,
    required this.isCompleted,
  });
}

class ProgressCalculator {
  static const double lessonWeight = 0.7;
  static const double quizWeight = 0.3;

  static ProgressResult calculate({
    required int totalLessons,
    required int completedLessonsCount,
    required List<double> quizBestPercentages, // e.g. [80.0, 100.0] for published quizzes
    required int totalPublishedQuizzesCount,
  }) {
    final double lessonPart = totalLessons > 0
        ? (completedLessonsCount / totalLessons).clamp(0.0, 1.0)
        : 0.0;

    double quizPart = 0.0;
    if (totalPublishedQuizzesCount > 0) {
      final double totalQuizScoreSum = quizBestPercentages.fold(0.0, (sum, score) => sum + score);
      quizPart = (totalQuizScoreSum / (totalPublishedQuizzesCount * 100.0)).clamp(0.0, 1.0);
    }

    final bool lessonsDone = totalLessons == 0 || completedLessonsCount >= totalLessons;
    final bool quizzesDone = totalPublishedQuizzesCount == 0 ||
        (quizBestPercentages.length >= totalPublishedQuizzesCount &&
         !quizBestPercentages.contains(0.0));

    double overallProgress = 0.0;
    if (lessonsDone && quizzesDone) {
      overallProgress = 1.0;
    } else if (totalLessons > 0 && totalPublishedQuizzesCount > 0) {
      overallProgress = (lessonWeight * lessonPart) + (quizWeight * quizPart);
    } else if (totalLessons > 0) {
      overallProgress = lessonPart;
    } else if (totalPublishedQuizzesCount > 0) {
      overallProgress = quizPart;
    }

    final bool completed = lessonsDone && quizzesDone;

    return ProgressResult(
      progressPercent: overallProgress.clamp(0.0, 1.0),
      lessonPercent: lessonPart,
      quizPercent: quizPart,
      isCompleted: completed,
    );
  }
}
