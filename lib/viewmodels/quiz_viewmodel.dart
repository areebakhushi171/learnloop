import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/course_repository.dart';

class QuizViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final AuthRepository _authRepository;
  final String courseId;

  bool _isLoading = true;
  QuizModel? _quiz;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  int _remainingSeconds = 180;
  bool _isFinished = false;
  int _scorePercent = 0;
  int _earnedXp = 0;
  bool _isPassed = false;
  Timer? _timer;

  QuizViewModel({
    required CourseRepository courseRepository,
    required AuthRepository authRepository,
    required this.courseId,
  })  : _courseRepository = courseRepository,
        _authRepository = authRepository {
    loadQuiz();
  }

  bool get isLoading => _isLoading;
  QuizModel? get quiz => _quiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  int get remainingSeconds => _remainingSeconds;
  bool get isFinished => _isFinished;
  int get scorePercent => _scorePercent;
  int get earnedXp => _earnedXp;
  bool get isPassed => _isPassed;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadQuiz() async {
    _isLoading = true;
    notifyListeners();

    final quiz = await _courseRepository.getQuizForCourse(courseId);
    if (quiz != null) {
      _quiz = quiz;
      _remainingSeconds = quiz.timeLimitSeconds;
      _isLoading = false;
      notifyListeners();
      _startTimer();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        finishQuiz(null);
      }
    });
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  void nextQuestion() {
    if (_quiz == null) return;
    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  Future<void> finishQuiz(String? userId) async {
    _timer?.cancel();
    final currentQuiz = _quiz;
    if (currentQuiz == null) return;

    int correct = 0;
    for (int i = 0; i < currentQuiz.questions.length; i++) {
      if (_selectedAnswers[i] == currentQuiz.questions[i].correctOptionIndex) {
        correct++;
      }
    }

    _scorePercent = ((correct / currentQuiz.questions.length) * 100).toInt();
    _earnedXp = (correct * AppConstants.xpPerQuizQuestionCorrect) +
        (_scorePercent == 100 ? AppConstants.xpBonusPerfectQuiz : 0);
    _isPassed = _scorePercent >= currentQuiz.passScorePercent;
    _isFinished = true;
    notifyListeners();

    if (userId != null) {
      final attempt = QuizAttemptModel(
        id: const Uuid().v4(),
        quizId: currentQuiz.id,
        courseId: courseId,
        scorePercent: _scorePercent,
        totalQuestions: currentQuiz.questions.length,
        correctQuestions: correct,
        selectedAnswers: _selectedAnswers,
        earnedXp: _earnedXp,
        completedAt: DateTime.now(),
      );

      await _courseRepository.recordQuizAttempt(userId, attempt);
      await _authRepository.updateStreakAndXp(userId, xpToAdd: _earnedXp);
    }
  }
}
