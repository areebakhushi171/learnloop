import 'package:flutter/material.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/course_repository.dart';

class AdminQuizBuilderViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final String courseId;
  final String? existingQuizId;

  bool _isLoading = false;
  String? _errorMessage;

  // Quiz Form Fields
  String _title = '';
  String _description = '';
  String _instructions = '';
  int _passingMarks = 70;
  int _timeLimitMinutes = 30;
  int _maxAttempts = 1;
  bool _isPublished = false;

  // Draft Questions
  final List<QuizQuestionModel> _questions = [];

  AdminQuizBuilderViewModel({
    required CourseRepository courseRepository,
    required this.courseId,
    this.existingQuizId,
  }) : _courseRepository = courseRepository {
    if (existingQuizId != null && existingQuizId!.isNotEmpty) {
      _loadExistingQuiz();
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get title => _title;
  String get description => _description;
  String get instructions => _instructions;
  int get passingMarks => _passingMarks;
  int get timeLimitMinutes => _timeLimitMinutes;
  int get maxAttempts => _maxAttempts;
  bool get isPublished => _isPublished;

  List<QuizQuestionModel> get questions => List.unmodifiable(_questions);
  int get totalMarks => _questions.fold<int>(0, (sum, q) => sum + q.marks);
  bool get canSave => _questions.isNotEmpty && _title.trim().isNotEmpty;

  void setQuizDetails({
    required String title,
    required String description,
    required String instructions,
    required int passingMarks,
    required int timeLimitMinutes,
    required int maxAttempts,
    required bool isPublished,
  }) {
    _title = title;
    _description = description;
    _instructions = instructions;
    _passingMarks = passingMarks;
    _timeLimitMinutes = timeLimitMinutes;
    _maxAttempts = maxAttempts;
    _isPublished = isPublished;
    notifyListeners();
  }

  void addQuestion(QuizQuestionModel question) {
    _questions.add(question);
    notifyListeners();
  }

  void updateQuestion(int index, QuizQuestionModel question) {
    if (index >= 0 && index < _questions.length) {
      _questions[index] = question;
      notifyListeners();
    }
  }

  void removeQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _questions.removeAt(index);
      notifyListeners();
    }
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _questions.removeAt(oldIndex);
    _questions.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> _loadExistingQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      final quiz = await _courseRepository.getQuizById(courseId, existingQuizId!);
      if (quiz != null) {
        _title = quiz.title;
        _description = quiz.description;
        _instructions = quiz.instructions;
        _passingMarks = quiz.passingMarks;
        _timeLimitMinutes = quiz.timeLimitMinutes;
        _maxAttempts = quiz.maxAttempts;
        _isPublished = quiz.isPublished;

        _questions.clear();
        _questions.addAll(quiz.questions);
      }
    } catch (e) {
      _errorMessage = 'Failed to load quiz details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveQuiz({required String createdByUserId}) async {
    if (_questions.isEmpty) {
      _errorMessage = 'Add at least one question to save this quiz.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final quiz = QuizModel(
        id: existingQuizId ?? '',
        courseId: courseId,
        title: _title.trim(),
        description: _description.trim(),
        instructions: _instructions.trim(),
        order: 0,
        totalMarks: totalMarks,
        passingMarks: _passingMarks,
        timeLimitMinutes: _timeLimitMinutes,
        maxAttempts: _maxAttempts,
        scoringAttempt: ScoringAttempt.best,
        gradingMode: GradingMode.auto,
        shuffleQuestions: false,
        shuffleOptions: false,
        showResultsMode: ShowResultsMode.immediately,
        allowExtensionRequests: true,
        isPublished: _isPublished,
        questionCount: _questions.length,
        createdBy: createdByUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingQuizId == null || existingQuizId!.isEmpty) {
        await _courseRepository.createQuizWithQuestions(courseId, quiz, _questions);
      } else {
        await _courseRepository.updateQuizWithQuestions(courseId, quiz, _questions);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save quiz: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
