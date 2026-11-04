import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String instructorName;
  final String? instructorAvatarUrl;
  final String thumbnailUrl;
  final double rating;
  final int totalRatings;
  final int durationMinutes;
  final int totalLessons;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final bool isFeatured;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.instructorName,
    this.instructorAvatarUrl,
    required this.thumbnailUrl,
    this.rating = 4.8,
    this.totalRatings = 120,
    required this.durationMinutes,
    required this.totalLessons,
    this.level = 'Beginner',
    this.isFeatured = false,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CourseModel(
      id: snapshot.id,
      title: data['title'] ?? 'Untitled Course',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Computer Science',
      instructorName: data['instructorName'] ?? 'Lead Instructor',
      instructorAvatarUrl: data['instructorAvatarUrl'],
      thumbnailUrl: data['thumbnailUrl'] ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 120,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 90,
      totalLessons: (data['totalLessons'] as num?)?.toInt() ?? 8,
      level: data['level'] ?? 'Beginner',
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'instructorName': instructorName,
      'instructorAvatarUrl': instructorAvatarUrl,
      'thumbnailUrl': thumbnailUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'durationMinutes': durationMinutes,
      'totalLessons': totalLessons,
      'level': level,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class EnrollmentModel {
  final String courseId;
  final String userId;
  final double progressPercent;
  final List<String> completedLessonIds;
  final String lastAccessedLessonId;
  final DateTime enrolledAt;
  final DateTime lastAccessedAt;

  const EnrollmentModel({
    required this.courseId,
    required this.userId,
    this.progressPercent = 0.0,
    this.completedLessonIds = const [],
    this.lastAccessedLessonId = '',
    required this.enrolledAt,
    required this.lastAccessedAt,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return EnrollmentModel(
      courseId: snapshot.id,
      userId: data['userId'] ?? '',
      progressPercent: (data['progressPercent'] as num?)?.toDouble() ?? 0.0,
      completedLessonIds: List<String>.from(data['completedLessonIds'] ?? []),
      lastAccessedLessonId: data['lastAccessedLessonId'] ?? '',
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'progressPercent': progressPercent,
      'completedLessonIds': completedLessonIds,
      'lastAccessedLessonId': lastAccessedLessonId,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
    };
  }
}
