import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedIndex
  int _remainingSeconds = 180;
  bool _isFinished = false;
  double _scorePercent = 0.0;
  int _correctCount = 0;
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
  double get scorePercent => _scorePercent;
  int get correctCount => _correctCount;
  bool get isPassed => _isPassed;
  int get earnedXp => _isPassed ? (_correctCount * 10) + 100 : (_correctCount * 10);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      final quiz = await _courseRepository.getQuizForCourse(courseId);
      if (quiz != null) {
        _quiz = quiz;
        _remainingSeconds = quiz.timeLimitMinutes * 60;
        _startTimer();
      }
    } catch (_) {
      _quiz = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        finishQuiz();
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

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<void> finishQuiz([String? userId]) async {
    _timer?.cancel();
    final currentQuiz = _quiz;
    if (currentQuiz == null) return;

    int correct = 0;
    for (int i = 0; i < currentQuiz.questions.length; i++) {
      final selected = _selectedAnswers[i];
      if (selected != null && selected == currentQuiz.questions[i].correctIndex) {
        correct++;
      }
    }

    _correctCount = correct;
    _scorePercent = currentQuiz.questions.isNotEmpty
        ? (correct / currentQuiz.questions.length) * 100
        : 0.0;
    _isPassed = _scorePercent >= currentQuiz.passingScore;
    _isFinished = true;
    notifyListeners();

    final uid = userId ?? _authRepository.currentUser?.uid;
    if (uid != null) {
      final stringAnswers = _selectedAnswers.map((k, v) => MapEntry(k.toString(), v));
      final attempt = QuizAttemptModel(
        id: const Uuid().v4(),
        courseId: courseId,
        quizId: currentQuiz.id,
        score: _scorePercent,
        correctCount: correct,
        totalQuestions: currentQuiz.questions.length,
        answers: stringAnswers,
        timeTakenSeconds: (currentQuiz.timeLimitMinutes * 60) - _remainingSeconds,
        passed: _isPassed,
        createdAt: DateTime.now(),
      );

      await _courseRepository.recordQuizAttempt(uid, attempt);
    }
  }
}
