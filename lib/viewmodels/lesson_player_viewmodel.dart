import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/lesson_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/course_repository.dart';

class LessonPlayerViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final AuthRepository _authRepository;
  final String courseId;
  final String lessonId;

  bool _isMarkingComplete = false;
  bool _isCompleted = false;
  String? _errorMessage;
  String _notes = '';

  LessonPlayerViewModel({
    required CourseRepository courseRepository,
    required AuthRepository authRepository,
    required this.courseId,
    required this.lessonId,
  })  : _courseRepository = courseRepository,
        _authRepository = authRepository;

  bool get isMarkingComplete => _isMarkingComplete;
  bool get isCompleted => _isCompleted;
  String? get errorMessage => _errorMessage;
  String get notes => _notes;

  void setNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  Stream<List<LessonModel>> get lessonsStream {
    return _courseRepository.streamLessons(courseId);
  }

  Future<bool> completeLesson(String userId, int totalLessons) async {
    _isMarkingComplete = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _courseRepository.markLessonComplete(
        userId,
        courseId,
        lessonId,
        totalLessons,
      );
      await _authRepository.updateStreakAndXp(
        userId,
        xpToAdd: AppConstants.xpPerLessonComplete,
      );
      _isMarkingComplete = false;
      _isCompleted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isMarkingComplete = false;
      notifyListeners();
      return false;
    }
  }
}
