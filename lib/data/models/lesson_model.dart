import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final String type; // "video" | "text" | "pdf"
  final String? videoUrl;
  final String content;
  final String? attachmentUrl;
  final int durationMinutes;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description = '',
    int? order,
    int? orderIndex,
    String? type,
    this.videoUrl,
    String? content,
    String? markdownContent,
    this.attachmentUrl,
    this.durationMinutes = 10,
  })  : order = order ?? orderIndex ?? 0,
        type = type ?? (videoUrl != null && videoUrl.isNotEmpty ? 'video' : 'text'),
        content = content ?? markdownContent ?? '';

  // Compatibility getters
  int get orderIndex => order;
  String get markdownContent => content;

  factory LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return LessonModel(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? 'Lesson',
      description: data['description'] ?? '',
      order: (data['order'] as num?)?.toInt() ?? (data['orderIndex'] as num?)?.toInt() ?? 0,
      type: data['type'] ?? (data['videoUrl'] != null && (data['videoUrl'] as String).isNotEmpty ? 'video' : 'text'),
      videoUrl: data['videoUrl'],
      content: data['content'] ?? data['markdownContent'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'type': type,
      'videoUrl': videoUrl,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'durationMinutes': durationMinutes,
    };
  }
}
