class AppConstants {
  static const String appName = 'LearnLoop';
  static const String appTagline = 'Master Your Learning Journey';

  // XP & Gamification Values
  static const int xpPerLessonComplete = 50;
  static const int xpPerQuizQuestionCorrect = 20;
  static const int xpBonusPerfectQuiz = 100;
  static const int xpDailyStreakBonus = 30;

  // Level thresholds
  static int getLevelFromXp(int xp) {
    if (xp <= 0) return 1;
    return (xp / 300).floor() + 1;
  }

  static int getXpRequiredForNextLevel(int currentLevel) {
    return currentLevel * 300;
  }

  // Course Categories
  static const List<String> categories = [
    'All',
    'Computer Science',
    'Mobile Dev',
    'Data Science',
    'UI/UX Design',
    'Business & Tech',
    'Cloud Computing',
  ];
}
