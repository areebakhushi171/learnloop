import 'package:flutter/material.dart';
import '../data/models/course_model.dart';
import '../data/models/lesson_model.dart';
import '../data/repositories/course_repository.dart';

class CourseDetailsViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final String courseId;

  bool _isLoading = true;
  bool _isEnrolling = false;
  CourseModel? _course;
  String? _errorMessage;

  CourseDetailsViewModel(this._courseRepository, this.courseId) {
    loadCourse();
  }

  bool get isLoading => _isLoading;
  bool get isEnrolling => _isEnrolling;
  CourseModel? get course => _course;
  String? get errorMessage => _errorMessage;

  Future<void> loadCourse() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _course = await _courseRepository.getCourseById(courseId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<LessonModel>> get lessonsStream {
    return _courseRepository.streamLessons(courseId);
  }

  Stream<EnrollmentModel?> streamEnrollment(String userId) {
    return _courseRepository.streamEnrollment(userId, courseId);
  }

  Future<bool> enroll(String userId) async {
    _isEnrolling = true;
    notifyListeners();

    try {
      await _courseRepository.enrollInCourse(userId, courseId);
      _isEnrolling = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isEnrolling = false;
      notifyListeners();
      return false;
    }
  }
}
