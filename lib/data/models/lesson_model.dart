import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int orderIndex;
  final int durationMinutes;
  final String? videoUrl;
  final String markdownContent;
  final bool hasQuiz;

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.durationMinutes,
    this.videoUrl,
    required this.markdownContent,
    this.hasQuiz = false,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return LessonModel(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? 'Lesson',
      description: data['description'] ?? '',
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 10,
      videoUrl: data['videoUrl'],
      markdownContent: data['markdownContent'] ?? '',
      hasQuiz: data['hasQuiz'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
      'durationMinutes': durationMinutes,
      'videoUrl': videoUrl,
      'markdownContent': markdownContent,
      'hasQuiz': hasQuiz,
    };
  }
}
