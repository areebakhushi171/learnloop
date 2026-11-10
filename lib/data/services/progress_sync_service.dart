import '../repositories/course_repository.dart';

class ProgressSyncService {
  final CourseRepository _courseRepository;

  ProgressSyncService(this._courseRepository);

  Future<void> syncCourseProgress(String userId, String courseId) async {
    try {
      await _courseRepository.recalculateAndSaveProgress(userId, courseId);
    } catch (_) {
      // Non-blocking sync
    }
  }
}
