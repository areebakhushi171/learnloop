import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';

class TopicProficiency {
  final String title;
  final double percent;
  final String tier;

  const TopicProficiency({
    required this.title,
    required this.percent,
    required this.tier,
  });
}

class ProgressViewModel extends ChangeNotifier {
  int _totalXp = 0;
  int _currentLevel = 1;
  int _nextLevelXp = 300;
  double _levelProgress = 0.0;
  final List<double> _weeklyHours = [1.5, 2.8, 3.2, 2.0, 4.5, 3.8, 1.2];
  final List<TopicProficiency> _topicProficiencies = const [
    TopicProficiency(title: 'State Architecture', percent: 0.92, tier: 'Master'),
    TopicProficiency(title: 'Algorithms & Complexity', percent: 0.78, tier: 'Proficient'),
    TopicProficiency(title: 'Data Structures', percent: 0.65, tier: 'Intermediate'),
    TopicProficiency(title: 'Concurrency & Streams', percent: 0.54, tier: 'Familiar'),
  ];

  int get totalXp => _totalXp;
  int get currentLevel => _currentLevel;
  int get nextLevelXp => _nextLevelXp;
  double get levelProgress => _levelProgress;
  List<double> get weeklyHours => _weeklyHours;
  List<TopicProficiency> get topicProficiencies => _topicProficiencies;

  void updateWithUser(UserModel? user) {
    if (user == null) return;
    _totalXp = user.totalXp;
    _currentLevel = AppConstants.getLevelFromXp(_totalXp);
    _nextLevelXp = AppConstants.getXpRequiredForNextLevel(_currentLevel);
    _levelProgress = ((_totalXp % 300) / 300.0).clamp(0.0, 1.0);
    notifyListeners();
  }
}
