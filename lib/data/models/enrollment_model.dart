import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String courseId;
  final String userId;
  final DateTime enrolledAt;
  final List<String> completedLessonIds;
  final double progressPercent;
  final String lastLessonId;
  final DateTime lastAccessedAt;
  final bool isCompleted;

  const EnrollmentModel({
    required this.courseId,
    required this.userId,
    required this.enrolledAt,
    required this.completedLessonIds,
    required this.progressPercent,
    required this.lastLessonId,
    required this.lastAccessedAt,
    required this.isCompleted,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return EnrollmentModel(
      courseId: snapshot.id,
      userId: data['userId'] ?? '',
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedLessonIds: List<String>.from(data['completedLessonIds'] ?? []),
      progressPercent: (data['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastLessonId: data['lastLessonId'] ?? data['lastAccessedLessonId'] ?? '',
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'completedLessonIds': completedLessonIds,
      'progressPercent': progressPercent,
      'lastLessonId': lastLessonId,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
      'isCompleted': isCompleted,
    };
  }
}
