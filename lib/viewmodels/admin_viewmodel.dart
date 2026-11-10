import 'package:flutter/material.dart';
import '../data/models/course_model.dart';
import '../data/models/lesson_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/course_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AdminViewModel(this._courseRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // --- Real-time Streams ---

  Stream<List<CourseModel>> get coursesStream => _courseRepository.streamCourses(includeUnpublished: true);
  Stream<List<UserModel>> get studentsStream => _courseRepository.streamAllStudents();
  Stream<List<EnrollmentModel>> get globalEnrollmentsStream => _courseRepository.streamAllEnrollmentsGrouped();
  Stream<List<LessonModel>> get globalLessonsStream => _courseRepository.streamAllLessonsGrouped();

  Stream<List<LessonModel>> streamLessons(String courseId) =>
      _courseRepository.streamLessons(courseId);

  Stream<List<EnrollmentModel>> streamStudentEnrollments(String userId) =>
      _courseRepository.streamUserEnrollments(userId);

  // --- Course CRUD ---

  Future<bool> saveCourse(CourseModel course) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.createOrUpdateCourse(course);
      _isLoading = false;
      _successMessage = course.id.isEmpty
          ? 'Course created successfully!'
          : 'Course updated successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save course: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.deleteCourse(courseId);
      _isLoading = false;
      _successMessage = 'Course deleted successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete course: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Lesson/Lecture CRUD ---

  Future<bool> saveLesson(String courseId, LessonModel lesson) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.createOrUpdateLesson(courseId, lesson);
      _isLoading = false;
      _successMessage = lesson.id.isEmpty
          ? 'Lecture added successfully!'
          : 'Lecture updated successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save lecture: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLesson(String courseId, String lessonId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.deleteLesson(courseId, lessonId);
      _isLoading = false;
      _successMessage = 'Lecture deleted successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete lecture: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Student & Enrollment Management ---

  Future<bool> assignCourse(String userId, String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.assignCourseToStudent(userId, courseId);
      _isLoading = false;
      _successMessage = 'Course assigned to student successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to assign course: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCourseAssignment(String userId, String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _courseRepository.removeCourseFromStudent(userId, courseId);
      _isLoading = false;
      _successMessage = 'Course enrollment revoked!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to revoke course: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStudentStatus(String userId, bool isDisabled) async {
    try {
      await _courseRepository.toggleUserStatus(userId, isDisabled);
      _successMessage = isDisabled ? 'Student account deactivated.' : 'Student account activated.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update student status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String userId) async {
    try {
      await _courseRepository.deleteStudentAccount(userId);
      _successMessage = 'Student account deleted.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete student: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveCourseCompletion(String userId, String courseId, bool approved) async {
    try {
      await _courseRepository.approveCourseCompletion(userId, courseId, approved);
      _successMessage = approved ? 'Course completion approved! Certificate unlocked.' : 'Certificate approval revoked.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update approval: $e';
      notifyListeners();
      return false;
    }
  }
}
