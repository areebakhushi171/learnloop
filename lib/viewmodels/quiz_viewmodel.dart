import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/course_repository.dart';
import '../domain/quiz_scorer.dart';
import '../domain/shuffle_service.dart';

class QuizViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final AuthRepository _authRepository;
  final String courseId;

  bool _isLoading = true;
  QuizModel? _quiz;
  int _currentQuestionIndex = 0;

  // Answers maps:
  // _selectedAnswers stores questionIndex -> original optionIndex (for scoring)
  // _displayedSelectedAnswers stores questionIndex -> displayed optionIndex (for UI selection state)
  final Map<int, int> _selectedAnswers = {};
  final Map<int, int> _displayedSelectedAnswers = {};

  // Map questionId -> List of original option indexes in displayed order
  final Map<String, List<int>> _optionOrders = {};

  int _remainingSeconds = 180;
  bool _isFinished = false;
  double _scorePercent = 0.0;
  int _correctCount = 0;
  bool _isPassed = false;
  Timer? _timer;

  final String? quizId;

  QuizViewModel({
    required CourseRepository courseRepository,
    required AuthRepository authRepository,
    required this.courseId,
    this.quizId,
  })  : _courseRepository = courseRepository,
        _authRepository = authRepository {
    loadQuiz();
  }

  bool get isLoading => _isLoading;
  QuizModel? get quiz => _quiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, int> get selectedAnswers => _displayedSelectedAnswers;
  Map<String, List<int>> get optionOrders => _optionOrders;
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
      QuizModel? quiz;
      if (quizId != null && quizId!.isNotEmpty) {
        quiz = await _courseRepository.getQuizById(courseId, quizId!);
      } else {
        quiz = await _courseRepository.getQuizForCourse(courseId);
      }

      if (quiz != null) {
        _quiz = quiz;
        _remainingSeconds = quiz.timeLimitMinutes * 60;

        // Generate shuffled option order per question
        _optionOrders.clear();
        for (var q in quiz.questions) {
          _optionOrders[q.id] = ShuffleService.shuffleOptionIndexes(q);
        }

        _startTimer();
      }
    } catch (_) {
      _quiz = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetQuizState() {
    _timer?.cancel();
    _currentQuestionIndex = 0;
    _selectedAnswers.clear();
    _displayedSelectedAnswers.clear();
    _isFinished = false;
    _scorePercent = 0.0;
    _correctCount = 0;
    _isPassed = false;
    if (_quiz != null) {
      _remainingSeconds = _quiz!.timeLimitMinutes * 60;
      _optionOrders.clear();
      for (var q in _quiz!.questions) {
        _optionOrders[q.id] = ShuffleService.shuffleOptionIndexes(q);
      }
      _startTimer();
    }
    notifyListeners();
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

  void selectAnswer(int questionIndex, int displayedOptionIndex) {
    if (_quiz == null) return;
    final q = _quiz!.questions[questionIndex];
    final order = _optionOrders[q.id] ?? List.generate(q.options.length, (i) => i);

    final originalIndex = order[displayedOptionIndex];
    _selectedAnswers[questionIndex] = originalIndex;
    _displayedSelectedAnswers[questionIndex] = displayedOptionIndex;
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

    int totalEarnedMarks = 0;
    int totalPossibleMarks = 0;
    int correctQuestions = 0;

    for (int i = 0; i < currentQuiz.questions.length; i++) {
      final q = currentQuiz.questions[i];
      totalPossibleMarks += q.marks;
      final originalSelected = _selectedAnswers[i];

      final marks = QuizScorer.scoreQuestion(
        question: q,
        selectedAnswer: originalSelected,
      );

      totalEarnedMarks += marks;
      if (marks > 0) {
        correctQuestions++;
      }
    }

    _correctCount = correctQuestions;
    _scorePercent = totalPossibleMarks > 0
        ? (totalEarnedMarks / totalPossibleMarks) * 100
        : 0.0;
    _isPassed = totalEarnedMarks >= currentQuiz.passingMarks;
    _isFinished = true;
    notifyListeners();

    final uid = userId ?? _authRepository.currentUser?.uid;
    if (uid != null) {
      try {
        final stringAnswers = _selectedAnswers.map((k, v) => MapEntry(k.toString(), v));
        final attempt = QuizAttemptModel(
          id: const Uuid().v4(),
          courseId: courseId,
          quizId: currentQuiz.id,
          score: _scorePercent,
          correctCount: correctQuestions,
          totalQuestions: currentQuiz.questions.length,
          answers: stringAnswers,
          optionOrder: _optionOrders,
          questionOrder: currentQuiz.questions.map((q) => q.id).toList(),
          timeTakenSeconds: (currentQuiz.timeLimitMinutes * 60) - _remainingSeconds,
          passed: _isPassed,
          createdAt: DateTime.now(),
        );

        await _courseRepository.recordQuizAttempt(uid, attempt);
      } catch (_) {
        // Non-blocking catch so result screen always remains displayed
      }
    }
  }
}
