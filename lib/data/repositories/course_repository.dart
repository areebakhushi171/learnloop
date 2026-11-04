import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/user_model.dart';

abstract class CourseRepository {
  Stream<List<CourseModel>> streamCourses({String? category, String? searchQuery});
  Future<CourseModel?> getCourseById(String id);
  Stream<List<LessonModel>> streamLessons(String courseId);
  Stream<EnrollmentModel?> streamEnrollment(String userId, String courseId);
  Stream<List<EnrollmentModel>> streamUserEnrollments(String userId);
  Future<void> enrollInCourse(String userId, String courseId);
  Future<void> markLessonComplete(String userId, String courseId, String lessonId, int totalCourseLessons);
  Future<QuizModel?> getQuizForCourse(String courseId);
  Future<void> recordQuizAttempt(String userId, QuizAttemptModel attempt);
  Stream<List<QuizAttemptModel>> streamUserQuizAttempts(String userId);

  // Admin Management Functions
  Future<void> createOrUpdateCourse(CourseModel course);
  Future<void> deleteCourse(String courseId);
  Future<void> createOrUpdateLesson(String courseId, LessonModel lesson);
  Future<void> deleteLesson(String courseId, String lessonId);

  Stream<List<UserModel>> streamAllStudents();
  Stream<List<EnrollmentModel>> streamAllEnrollmentsGrouped();
  Stream<List<LessonModel>> streamAllLessonsGrouped();
  Future<void> assignCourseToStudent(String userId, String courseId);
  Future<void> removeCourseFromStudent(String userId, String courseId);
  Future<void> toggleUserStatus(String userId, bool isDisabled);
  Future<void> deleteStudentAccount(String userId);
}

class FirestoreCourseRepository implements CourseRepository {
  final FirebaseFirestore _firestore;

  FirestoreCourseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<CourseModel>> streamCourses({String? category, String? searchQuery}) {
    Query<Map<String, dynamic>> query = _firestore.collection('courses');
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.toLowerCase().trim();
        return list
            .where((c) =>
                c.title.toLowerCase().contains(queryLower) ||
                c.description.toLowerCase().contains(queryLower) ||
                c.instructorName.toLowerCase().contains(queryLower))
            .toList();
      }
      return list;
    });
  }

  @override
  Future<CourseModel?> getCourseById(String id) async {
    final doc = await _firestore.collection('courses').doc(id).get();
    if (!doc.exists) return null;
    return CourseModel.fromFirestore(doc);
  }

  @override
  Stream<List<LessonModel>> streamLessons(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<EnrollmentModel?> streamEnrollment(String userId, String courseId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId)
        .snapshots()
        .map((doc) => doc.exists ? EnrollmentModel.fromFirestore(doc) : null);
  }

  @override
  Stream<List<EnrollmentModel>> streamUserEnrollments(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EnrollmentModel.fromFirestore(doc)).toList());
  }

  @override
  Future<void> enrollInCourse(String userId, String courseId) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId);

    final existing = await ref.get();
    if (existing.exists) return;

    final enrollment = EnrollmentModel(
      courseId: courseId,
      userId: userId,
      progressPercent: 0.0,
      completedLessonIds: const [],
      enrolledAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
    );
    await ref.set(enrollment.toFirestore());
  }

  @override
  Future<void> markLessonComplete(
    String userId,
    String courseId,
    String lessonId,
    int totalCourseLessons,
  ) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      List<String> completed = [];
      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        completed = List<String>.from(data['completedLessonIds'] ?? []);
      }

      if (!completed.contains(lessonId)) {
        completed.add(lessonId);
      }

      final double progress = totalCourseLessons > 0
          ? (completed.length / totalCourseLessons).clamp(0.0, 1.0)
          : 1.0;

      transaction.set(
        ref,
        {
          'userId': userId,
          'progressPercent': progress,
          'completedLessonIds': completed,
          'lastAccessedLessonId': lessonId,
          'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<QuizModel?> getQuizForCourse(String courseId) async {
    final snapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return QuizModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<void> recordQuizAttempt(String userId, QuizAttemptModel attempt) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('quizAttempts')
        .doc(attempt.id);

    await ref.set(attempt.toFirestore());
  }

  @override
  Stream<List<QuizAttemptModel>> streamUserQuizAttempts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('quizAttempts')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuizAttemptModel.fromFirestore(doc)).toList());
  }

  // --- Admin Functions Implementation ---

  @override
  Future<void> createOrUpdateCourse(CourseModel course) async {
    final docId = course.id.isEmpty
        ? _firestore.collection('courses').doc().id
        : course.id;

    final updatedCourse = CourseModel(
      id: docId,
      title: course.title,
      description: course.description,
      category: course.category,
      instructorName: course.instructorName,
      instructorAvatarUrl: course.instructorAvatarUrl,
      thumbnailUrl: course.thumbnailUrl,
      rating: course.rating,
      totalRatings: course.totalRatings,
      durationMinutes: course.durationMinutes,
      totalLessons: course.totalLessons,
      level: course.level,
      isFeatured: course.isFeatured,
      createdAt: course.createdAt,
    );

    await _firestore.collection('courses').doc(docId).set(
          updatedCourse.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
  }

  @override
  Future<void> createOrUpdateLesson(String courseId, LessonModel lesson) async {
    final lessonDocRef = lesson.id.isEmpty
        ? _firestore.collection('courses').doc(courseId).collection('lessons').doc()
        : _firestore.collection('courses').doc(courseId).collection('lessons').doc(lesson.id);

    final lessonData = {
      'courseId': courseId,
      'title': lesson.title,
      'description': lesson.description,
      'orderIndex': lesson.orderIndex,
      'durationMinutes': lesson.durationMinutes,
      'videoUrl': lesson.videoUrl,
      'markdownContent': lesson.markdownContent,
      'hasQuiz': lesson.hasQuiz,
    };

    await lessonDocRef.set(lessonData, SetOptions(merge: true));

    // Update totalLessons count on course document
    final lessonsSnap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .get();

    await _firestore.collection('courses').doc(courseId).update({
      'totalLessons': lessonsSnap.docs.length,
    });
  }

  @override
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .delete();

    final lessonsSnap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .get();

    await _firestore.collection('courses').doc(courseId).update({
      'totalLessons': lessonsSnap.docs.length,
    });
  }

  @override
  Stream<List<UserModel>> streamAllStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<EnrollmentModel>> streamAllEnrollmentsGrouped() {
    return _firestore
        .collectionGroup('enrollments')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EnrollmentModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<LessonModel>> streamAllLessonsGrouped() {
    return _firestore
        .collectionGroup('lessons')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  @override
  Future<void> assignCourseToStudent(String userId, String courseId) async {
    await enrollInCourse(userId, courseId);
  }

  @override
  Future<void> removeCourseFromStudent(String userId, String courseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId)
        .delete();
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isDisabled) async {
    await _firestore.collection('users').doc(userId).update({
      'isDisabled': isDisabled,
    });
  }

  @override
  Future<void> deleteStudentAccount(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
