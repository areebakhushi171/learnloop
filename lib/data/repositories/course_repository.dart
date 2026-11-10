import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/progress_calculator.dart';
import '../models/category_model.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../models/study_log_model.dart';
import '../models/achievement_model.dart';
import '../models/reminder_model.dart';

abstract class CourseRepository {
  // Categories
  Stream<List<CategoryModel>> streamCategories();
  Future<void> createOrUpdateCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);

  // Courses
  Stream<List<CourseModel>> streamCourses({String? categoryId, String? searchQuery, String? level, String? category, bool includeUnpublished = false});
  Future<CourseModel?> getCourseById(String courseId);
  Future<void> createOrUpdateCourse(CourseModel course, [File? thumbnailFile]);
  Future<void> deleteCourse(String courseId);
  Future<void> togglePublishCourse(String courseId, bool isPublished);

  // Lessons
  Stream<List<LessonModel>> streamLessons(String courseId);
  Future<void> createOrUpdateLesson(String courseId, LessonModel lesson, [File? pdfFile]);
  Future<void> deleteLesson(String courseId, String lessonId);

  // Quizzes & Questions
  Stream<List<QuizModel>> streamQuizzes(String courseId);
  Future<QuizModel?> getQuizById(String courseId, String quizId);
  Future<QuizModel?> getQuizForCourse(String courseId);
  Future<void> createQuizWithQuestions(String courseId, QuizModel quiz, List<QuizQuestionModel> questions);
  Future<void> updateQuizWithQuestions(String courseId, QuizModel quiz, List<QuizQuestionModel> questions);
  Future<void> deleteQuiz(String courseId, String quizId);
  Stream<List<QuizQuestionModel>> streamQuestions(String courseId, String quizId);
  Future<void> createOrUpdateQuestion(String courseId, String quizId, QuizQuestionModel question);
  Future<void> deleteQuestion(String courseId, String quizId, String questionId);
  Future<void> deleteEmptyQuizzes(String courseId);

  // Enrollments & Progress
  Stream<EnrollmentModel?> streamEnrollment(String userId, String courseId);
  Stream<List<EnrollmentModel>> streamUserEnrollments(String userId);
  Future<void> enrollInCourse(String userId, String courseId);
  Future<void> approveCourseCompletion(String userId, String courseId, bool approved);
  Future<void> markLessonComplete(String userId, String courseId, String lessonId, int totalLessons, [int lessonDurationMinutes = 10]);
  Future<void> recalculateAndSaveProgress(String userId, String courseId);

  // Quiz Attempts
  Future<void> recordQuizAttempt(String userId, QuizAttemptModel attempt);
  Stream<List<QuizAttemptModel>> streamUserQuizAttempts(String userId, String courseId);
  Stream<List<QuizAttemptModel>> streamAllUserQuizAttempts(String userId);

  // Study Logs & Leaderboard & Bookmarks
  Stream<StudyLogModel?> streamStudyLog(String userId, String dateKey);
  Stream<List<StudyLogModel>> streamUserStudyLogs(String userId);
  Stream<List<UserModel>> streamLeaderboard();
  Future<void> toggleBookmark(String userId, String courseId);
  Stream<List<CourseModel>> streamBookmarkedCourses(List<String> bookmarkedIds);

  // Reminders & Achievements
  Stream<List<ReminderModel>> streamReminders(String userId);
  Future<void> saveReminder(String userId, ReminderModel reminder);
  Future<void> deleteReminder(String userId, String reminderId);
  Stream<List<AchievementModel>> streamAchievements(String userId);

  // Admin Student & Global Management
  Stream<List<UserModel>> streamAllStudents();
  Stream<List<EnrollmentModel>> streamAllEnrollments();
  Stream<List<EnrollmentModel>> streamAllEnrollmentsGrouped();
  Stream<List<LessonModel>> streamAllLessonsGrouped();
  Future<void> toggleUserStatus(String userId, bool isDisabled);
  Future<void> deleteStudentAccount(String userId);
  Future<void> assignCourseToStudent(String userId, String courseId);
  Future<void> removeCourseFromStudent(String userId, String courseId);

  // Storage
  Future<String> uploadFile(String path, File file);
}

class FirestoreCourseRepository implements CourseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestoreCourseRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<List<CategoryModel>> streamCategories() {
    return _firestore.collection('categories').snapshots().map((snap) {
      final list = snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  @override
  Future<void> createOrUpdateCategory(CategoryModel category) async {
    final ref = category.id.isEmpty
        ? _firestore.collection('categories').doc()
        : _firestore.collection('categories').doc(category.id);
    await ref.set({
      'name': category.name,
      'icon': category.icon,
      'order': category.order,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  @override
  Stream<List<CourseModel>> streamCourses({
    String? categoryId,
    String? searchQuery,
    String? level,
    String? category,
    bool includeUnpublished = false,
  }) {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();

      if (!includeUnpublished) {
        list = list.where((c) => c.isPublished).toList();
      }

      final activeCat = categoryId ?? category;
      if (activeCat != null && activeCat.isNotEmpty && activeCat != 'All') {
        list = list.where((c) => c.categoryId == activeCat || c.category == activeCat).toList();
      }

      if (level != null && level.isNotEmpty && level != 'All') {
        list = list.where((c) => c.level.toLowerCase() == level.toLowerCase()).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.toLowerCase().trim();
        list = list.where((c) =>
            c.title.toLowerCase().contains(queryLower) ||
            c.description.toLowerCase().contains(queryLower) ||
            c.instructorName.toLowerCase().contains(queryLower)).toList();
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<CourseModel?> getCourseById(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromFirestore(doc);
  }

  @override
  Future<void> createOrUpdateCourse(CourseModel course, [File? thumbnailFile]) async {
    String thumbnailUrl = course.thumbnailUrl;
    if (thumbnailFile != null) {
      thumbnailUrl = await uploadFile('course_thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg', thumbnailFile);
    }

    final docId = course.id.isEmpty ? _firestore.collection('courses').doc().id : course.id;
    final now = DateTime.now();

    final courseData = {
      'title': course.title,
      'description': course.description,
      'categoryId': course.categoryId,
      'thumbnailUrl': thumbnailUrl,
      'instructorId': course.instructorId,
      'instructorName': course.instructorName,
      'level': course.level,
      'durationMinutes': course.durationMinutes,
      'lessonCount': course.lessonCount,
      'quizCount': course.quizCount,
      'enrolledCount': course.enrolledCount,
      'ratingAvg': course.ratingAvg,
      'ratingCount': course.ratingCount,
      'isPublished': course.isPublished,
      'createdAt': Timestamp.fromDate(course.createdAt.year == 1970 ? now : course.createdAt),
      'updatedAt': Timestamp.fromDate(now),
    };

    await _firestore.collection('courses').doc(docId).set(courseData, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
  }

  @override
  Future<void> togglePublishCourse(String courseId, bool isPublished) async {
    await _firestore.collection('courses').doc(courseId).update({'isPublished': isPublished});
  }

  @override
  Stream<List<LessonModel>> streamLessons(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => LessonModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  @override
  Future<void> createOrUpdateLesson(String courseId, LessonModel lesson, [File? pdfFile]) async {
    String? attachmentUrl = lesson.attachmentUrl;
    if (pdfFile != null) {
      attachmentUrl = await uploadFile('course_lessons/$courseId/${DateTime.now().millisecondsSinceEpoch}.pdf', pdfFile);
    }

    final docId = lesson.id.isEmpty
        ? _firestore.collection('courses').doc(courseId).collection('lessons').doc().id
        : lesson.id;

    final lessonData = {
      'courseId': courseId,
      'title': lesson.title,
      'order': lesson.order,
      'type': lesson.type,
      'videoUrl': lesson.videoUrl,
      'content': lesson.content,
      'attachmentUrl': attachmentUrl,
      'durationMinutes': lesson.durationMinutes,
    };

    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(docId)
        .set(lessonData, SetOptions(merge: true));

    final lessonsSnap = await _firestore.collection('courses').doc(courseId).collection('lessons').get();
    await _firestore.collection('courses').doc(courseId).update({'lessonCount': lessonsSnap.docs.length});
  }

  @override
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _firestore.collection('courses').doc(courseId).collection('lessons').doc(lessonId).delete();
    final lessonsSnap = await _firestore.collection('courses').doc(courseId).collection('lessons').get();
    await _firestore.collection('courses').doc(courseId).update({'lessonCount': lessonsSnap.docs.length});
  }

  @override
  Stream<List<QuizModel>> streamQuizzes(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => QuizModel.fromFirestore(d)).toList());
  }

  @override
  Future<QuizModel?> getQuizById(String courseId, String quizId) async {
    final doc = await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).get();
    if (!doc.exists) return null;
    final questionsSnap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .get();
    final questions = questionsSnap.docs.map((q) => QuizQuestionModel.fromFirestore(q)).toList();
    questions.sort((a, b) => a.order.compareTo(b.order));
    return QuizModel.fromFirestore(doc, questions: questions);
  }

  @override
  Future<QuizModel?> getQuizForCourse(String courseId) async {
    final snap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .get();

    final activeQuizzes = snap.docs
        .map((d) => QuizModel.fromFirestore(d))
        .where((q) => q.isPublished && q.questionCount > 0)
        .toList();

    if (activeQuizzes.isEmpty) return null;
    final quiz = activeQuizzes.first;

    final questionsSnap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quiz.id)
        .collection('questions')
        .get();

    final questions = questionsSnap.docs.map((q) => QuizQuestionModel.fromFirestore(q)).toList();
    questions.sort((a, b) => a.order.compareTo(b.order));
    return quiz.copyWithQuestions(questions);
  }

  @override
  Future<void> createQuizWithQuestions(String courseId, QuizModel quiz, List<QuizQuestionModel> questions) async {
    if (questions.isEmpty) {
      throw Exception('A quiz must contain at least one question.');
    }

    final batch = _firestore.batch();
    final quizRef = _firestore.collection('courses').doc(courseId).collection('quizzes').doc();
    final totalMarks = questions.fold<int>(0, (acc, q) => acc + q.marks);

    final quizData = {
      'courseId': courseId,
      'title': quiz.title,
      'description': quiz.description,
      'instructions': quiz.instructions,
      'order': quiz.order,
      'totalMarks': totalMarks,
      'passingMarks': quiz.passingMarks,
      'timeLimitMinutes': quiz.timeLimitMinutes,
      'startAt': quiz.startAt != null ? Timestamp.fromDate(quiz.startAt!) : null,
      'dueAt': quiz.dueAt != null ? Timestamp.fromDate(quiz.dueAt!) : null,
      'maxAttempts': quiz.maxAttempts,
      'scoringAttempt': quiz.scoringAttempt.name,
      'gradingMode': quiz.gradingMode.name,
      'shuffleQuestions': quiz.shuffleQuestions,
      'shuffleOptions': quiz.shuffleOptions,
      'showResultsMode': quiz.showResultsMode.name,
      'allowExtensionRequests': quiz.allowExtensionRequests,
      'isPublished': quiz.isPublished,
      'questionCount': questions.length,
      'createdBy': quiz.createdBy,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    batch.set(quizRef, quizData);

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qRef = quizRef.collection('questions').doc();
      batch.set(qRef, {
        'type': q.type.name,
        'text': q.text,
        'imageUrl': q.imageUrl,
        'options': q.options,
        'correctIndexes': q.correctIndexes,
        'marks': q.marks,
        'explanation': q.explanation,
        'topic': q.topic,
        'order': i,
      });
    }

    await batch.commit();

    final quizzesSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').get();
    await _firestore.collection('courses').doc(courseId).update({'quizCount': quizzesSnap.docs.length});
  }

  @override
  Future<void> updateQuizWithQuestions(String courseId, QuizModel quiz, List<QuizQuestionModel> questions) async {
    if (questions.isEmpty) {
      throw Exception('A quiz must contain at least one question.');
    }

    final batch = _firestore.batch();
    final quizRef = _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quiz.id);
    final totalMarks = questions.fold<int>(0, (acc, q) => acc + q.marks);

    batch.set(quizRef, {
      'title': quiz.title,
      'description': quiz.description,
      'instructions': quiz.instructions,
      'totalMarks': totalMarks,
      'passingMarks': quiz.passingMarks,
      'timeLimitMinutes': quiz.timeLimitMinutes,
      'maxAttempts': quiz.maxAttempts,
      'isPublished': quiz.isPublished,
      'questionCount': questions.length,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    final existingSnap = await quizRef.collection('questions').get();
    for (var doc in existingSnap.docs) {
      batch.delete(doc.reference);
    }

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qRef = quizRef.collection('questions').doc();
      batch.set(qRef, {
        'type': q.type.name,
        'text': q.text,
        'imageUrl': q.imageUrl,
        'options': q.options,
        'correctIndexes': q.correctIndexes,
        'marks': q.marks,
        'explanation': q.explanation,
        'topic': q.topic,
        'order': i,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> createOrUpdateQuestion(String courseId, String quizId, QuizQuestionModel question) async {
    final docId = question.id.isEmpty
        ? _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).collection('questions').doc().id
        : question.id;

    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .doc(docId)
        .set(question.toFirestore(), SetOptions(merge: true));

    final questionsSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).collection('questions').get();
    await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).update({
      'questionCount': questionsSnap.docs.length,
    });
  }

  @override
  Future<void> deleteQuestion(String courseId, String quizId, String questionId) async {
    await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).collection('questions').doc(questionId).delete();
    final questionsSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).collection('questions').get();
    await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).update({
      'questionCount': questionsSnap.docs.length,
    });
  }

  @override
  Future<void> deleteQuiz(String courseId, String quizId) async {
    await _firestore.collection('courses').doc(courseId).collection('quizzes').doc(quizId).delete();
    final quizzesSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').get();
    await _firestore.collection('courses').doc(courseId).update({'quizCount': quizzesSnap.docs.length});
  }

  @override
  Stream<List<QuizQuestionModel>> streamQuestions(String courseId, String quizId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => QuizQuestionModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  @override
  Future<void> deleteEmptyQuizzes(String courseId) async {
    final quizzesSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').get();
    for (var doc in quizzesSnap.docs) {
      final qCount = (doc.data()['questionCount'] as num?)?.toInt() ?? 0;
      if (qCount == 0) {
        await doc.reference.delete();
      }
    }
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
        .map((snap) => snap.docs.map((d) => EnrollmentModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> enrollInCourse(String userId, String courseId) async {
    final enrollmentRef = _firestore.collection('users').doc(userId).collection('enrollments').doc(courseId);
    final courseRef = _firestore.collection('courses').doc(courseId);

    await _firestore.runTransaction((tx) async {
      final enrollmentDoc = await tx.get(enrollmentRef);
      if (enrollmentDoc.exists) return;

      final courseDoc = await tx.get(courseRef);
      final currentEnrolled = courseDoc.exists ? ((courseDoc.data()?['enrolledCount'] as num?)?.toInt() ?? 0) : 0;

      tx.set(enrollmentRef, {
        'userId': userId,
        'enrolledAt': Timestamp.fromDate(DateTime.now()),
        'completedLessonIds': [],
        'progressPercent': 0.0,
        'lastLessonId': '',
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
      });

      if (courseDoc.exists) {
        tx.update(courseRef, {'enrolledCount': currentEnrolled + 1});
      }
    });

    await recalculateAndSaveProgress(userId, courseId);
  }

  @override
  Future<void> markLessonComplete(
    String userId,
    String courseId,
    String lessonId,
    int totalLessons, [
    int lessonDurationMinutes = 10,
  ]) async {
    final enrollmentRef = _firestore.collection('users').doc(userId).collection('enrollments').doc(courseId);
    final userRef = _firestore.collection('users').doc(userId);
    final todayKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final studyLogRef = userRef.collection('studyLogs').doc(todayKey);

    await _firestore.runTransaction((tx) async {
      final enrollmentSnap = await tx.get(enrollmentRef);
      List<String> completed = [];
      if (enrollmentSnap.exists) {
        completed = List<String>.from(enrollmentSnap.data()?['completedLessonIds'] ?? []);
      }

      bool isNewCompletion = !completed.contains(lessonId);
      if (isNewCompletion) {
        completed.add(lessonId);
      }

      tx.set(enrollmentRef, {
        'userId': userId,
        'completedLessonIds': completed,
        'lastLessonId': lessonId,
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      final studyLogSnap = await tx.get(studyLogRef);
      int currentSecs = studyLogSnap.exists ? ((studyLogSnap.data()?['seconds'] as num?)?.toInt() ?? 0) : 0;
      int currentLessonsCompleted = studyLogSnap.exists ? ((studyLogSnap.data()?['lessonsCompleted'] as num?)?.toInt() ?? 0) : 0;

      tx.set(studyLogRef, {
        'seconds': currentSecs + (lessonDurationMinutes * 60),
        'lessonsCompleted': isNewCompletion ? currentLessonsCompleted + 1 : currentLessonsCompleted,
      }, SetOptions(merge: true));

      final userSnap = await tx.get(userRef);
      if (userSnap.exists) {
        final userData = userSnap.data() ?? {};
        int currentXp = (userData['xp'] as num?)?.toInt() ?? 0;
        int totalSecs = (userData['totalStudySeconds'] as num?)?.toInt() ?? 0;
        int xpGain = isNewCompletion ? 50 : 0;
        int newXp = currentXp + xpGain;
        int newLevel = (newXp ~/ 500) + 1;

        tx.update(userRef, {
          'xp': newXp,
          'totalStudySeconds': totalSecs + (lessonDurationMinutes * 60),
          'level': newLevel,
        });
      }
    });

    await recalculateAndSaveProgress(userId, courseId);
  }

  @override
  Future<void> recalculateAndSaveProgress(String userId, String courseId) async {
    // 1. Fetch Lessons
    final lessonsSnap = await _firestore.collection('courses').doc(courseId).collection('lessons').get();
    final totalLessons = lessonsSnap.docs.length;

    // 2. Fetch Quizzes (Published with questionCount > 0)
    final quizzesSnap = await _firestore.collection('courses').doc(courseId).collection('quizzes').get();
    final publishedQuizzes = quizzesSnap.docs
        .map((d) => QuizModel.fromFirestore(d))
        .where((q) => q.isPublished && q.questionCount > 0)
        .toList();

    // 3. Fetch User Attempts for this Course
    final attemptsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('quizAttempts')
        .get();

    final attempts = attemptsSnap.docs
        .map((d) => QuizAttemptModel.fromFirestore(d))
        .where((a) => a.courseId == courseId)
        .toList();

    // Map best attempt percentage per published quiz
    final List<double> quizBestPercentages = [];
    for (var quiz in publishedQuizzes) {
      final quizAttempts = attempts.where((a) => a.quizId == quiz.id).toList();
      if (quizAttempts.isNotEmpty) {
        quizAttempts.sort((a, b) => b.score.compareTo(a.score));
        quizBestPercentages.add(quizAttempts.first.score);
      } else {
        quizBestPercentages.add(0.0);
      }
    }

    // 4. Fetch Enrollment Completed Lessons
    final enrollmentRef = _firestore.collection('users').doc(userId).collection('enrollments').doc(courseId);
    final enrollmentSnap = await enrollmentRef.get();
    int completedLessonsCount = 0;
    if (enrollmentSnap.exists) {
      final data = enrollmentSnap.data() ?? {};
      final completedList = List<String>.from(data['completedLessonIds'] ?? []);
      completedLessonsCount = completedList.length;
    }

    // 5. Calculate via ProgressCalculator
    final result = ProgressCalculator.calculate(
      totalLessons: totalLessons,
      completedLessonsCount: completedLessonsCount,
      quizBestPercentages: quizBestPercentages,
      totalPublishedQuizzesCount: publishedQuizzes.length,
    );

    // 6. Save updated progress to Enrollment Document
    await enrollmentRef.set({
      'userId': userId,
      'progressPercent': result.progressPercent,
      'lessonPercent': result.lessonPercent,
      'quizPercent': result.quizPercent,
      'isCompleted': result.isCompleted,
      'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> recordQuizAttempt(String userId, QuizAttemptModel attempt) async {
    final attemptRef = _firestore.collection('users').doc(userId).collection('quizAttempts').doc(attempt.id);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((tx) async {
      tx.set(attemptRef, attempt.toFirestore());

      if (attempt.passed) {
        final userSnap = await tx.get(userRef);
        if (userSnap.exists) {
          final userData = userSnap.data() ?? {};
          int currentXp = (userData['xp'] as num?)?.toInt() ?? 0;
          int newXp = currentXp + 100;
          int newLevel = (newXp ~/ 500) + 1;

          tx.update(userRef, {
            'xp': newXp,
            'level': newLevel,
          });
        }
      }
    });

    // Automatically recalculate course progress after quiz attempt
    await recalculateAndSaveProgress(userId, attempt.courseId);
  }

  @override
  Stream<List<QuizAttemptModel>> streamUserQuizAttempts(String userId, String courseId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('quizAttempts')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => QuizAttemptModel.fromFirestore(d)).toList();
      return list.where((a) => a.courseId == courseId).toList();
    });
  }

  @override
  Stream<List<QuizAttemptModel>> streamAllUserQuizAttempts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('quizAttempts')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => QuizAttemptModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<StudyLogModel?> streamStudyLog(String userId, String dateKey) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('studyLogs')
        .doc(dateKey)
        .snapshots()
        .map((doc) => doc.exists ? StudyLogModel.fromFirestore(doc) : null);
  }

  @override
  Stream<List<StudyLogModel>> streamUserStudyLogs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('studyLogs')
        .snapshots()
        .map((snap) => snap.docs.map((d) => StudyLogModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<UserModel>> streamLeaderboard() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.xp.compareTo(a.xp));
      return list.take(50).toList();
    });
  }

  @override
  Future<void> toggleBookmark(String userId, String courseId) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return;
      List<String> bookmarks = List<String>.from(snap.data()?['bookmarkedCourseIds'] ?? []);
      if (bookmarks.contains(courseId)) {
        bookmarks.remove(courseId);
      } else {
        bookmarks.add(courseId);
      }
      tx.update(userRef, {'bookmarkedCourseIds': bookmarks});
    });
  }

  @override
  Stream<List<CourseModel>> streamBookmarkedCourses(List<String> bookmarkedIds) {
    if (bookmarkedIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: bookmarkedIds)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<ReminderModel>> streamReminders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReminderModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> saveReminder(String userId, ReminderModel reminder) async {
    final ref = reminder.id.isEmpty
        ? _firestore.collection('users').doc(userId).collection('reminders').doc()
        : _firestore.collection('users').doc(userId).collection('reminders').doc(reminder.id);
    await ref.set(reminder.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteReminder(String userId, String reminderId) async {
    await _firestore.collection('users').doc(userId).collection('reminders').doc(reminderId).delete();
  }

  @override
  Stream<List<AchievementModel>> streamAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AchievementModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<UserModel>> streamAllStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<EnrollmentModel>> streamAllEnrollments() {
    return _firestore
        .collectionGroup('enrollments')
        .snapshots()
        .map((snap) => snap.docs.map((d) => EnrollmentModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<EnrollmentModel>> streamAllEnrollmentsGrouped() => streamAllEnrollments();

  @override
  Stream<List<LessonModel>> streamAllLessonsGrouped() {
    return _firestore
        .collectionGroup('lessons')
        .snapshots()
        .map((snap) => snap.docs.map((d) => LessonModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isDisabled) async {
    await _firestore.collection('users').doc(userId).update({'isDisabled': isDisabled});
  }

  @override
  Future<void> deleteStudentAccount(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  @override
  Future<void> assignCourseToStudent(String userId, String courseId) async {
    await enrollInCourse(userId, courseId);
  }

  @override
  Future<void> removeCourseFromStudent(String userId, String courseId) async {
    await _firestore.collection('users').doc(userId).collection('enrollments').doc(courseId).delete();
  }

  @override
  Future<void> approveCourseCompletion(String userId, String courseId, bool approved) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId)
        .update({'adminApproved': approved});
  }

  @override
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
