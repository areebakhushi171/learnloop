import 'package:cloud_firestore/cloud_firestore.dart';
export 'enrollment_model.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String thumbnailUrl;
  final String instructorId;
  final String instructorName;
  final String level; // "Beginner" | "Intermediate" | "Advanced"
  final int durationMinutes;
  final int lessonCount;
  final int quizCount;
  final int enrolledCount;
  final double ratingAvg;
  final int ratingCount;
  final bool isPublished;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    String? categoryId,
    String? category,
    required this.thumbnailUrl,
    this.instructorId = '',
    required this.instructorName,
    this.level = 'Beginner',
    this.durationMinutes = 60,
    int? lessonCount,
    int? totalLessons,
    this.quizCount = 0,
    this.enrolledCount = 0,
    double? ratingAvg,
    double? rating,
    int? ratingCount,
    int? totalRatings,
    this.isPublished = true,
    this.isFeatured = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : categoryId = categoryId ?? category ?? 'General',
        lessonCount = lessonCount ?? totalLessons ?? 0,
        ratingAvg = ratingAvg ?? rating ?? 4.8,
        ratingCount = ratingCount ?? totalRatings ?? 120,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Compatibility getters
  String get category => categoryId;
  int get totalLessons => lessonCount;
  double get rating => ratingAvg;
  int get totalRatings => ratingCount;

  factory CourseModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CourseModel(
      id: snapshot.id,
      title: data['title'] ?? 'Untitled Course',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? data['category'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'] ?? 'Instructor',
      level: data['level'] ?? 'Beginner',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
      lessonCount: (data['lessonCount'] as num?)?.toInt() ?? (data['totalLessons'] as num?)?.toInt() ?? 0,
      quizCount: (data['quizCount'] as num?)?.toInt() ?? 0,
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 0,
      ratingAvg: (data['ratingAvg'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 4.8,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? (data['totalRatings'] as num?)?.toInt() ?? 120,
      isPublished: data['isPublished'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'thumbnailUrl': thumbnailUrl,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'level': level,
      'durationMinutes': durationMinutes,
      'lessonCount': lessonCount,
      'quizCount': quizCount,
      'enrolledCount': enrolledCount,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
