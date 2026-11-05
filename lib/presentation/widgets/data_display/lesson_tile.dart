import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/repositories/course_repository.dart';

enum LessonTileMode { student, admin }

class LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final LessonTileMode mode;
  final String courseId;
  final VoidCallback? onEdit;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.mode,
    required this.courseId,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == LessonTileMode.admin) {
      return ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('${lesson.orderIndex + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(lesson.title),
        subtitle: Text('${lesson.durationMinutes} mins • ${lesson.type.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: onEdit,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              onPressed: () async {
                final courseRepo = context.read<CourseRepository>();
                await courseRepo.deleteLesson(courseId, lesson.id);
              },
            ),
          ],
        ),
      );
    }

    // Student Mode
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        child: Text('${lesson.orderIndex + 1}', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(lesson.title),
      subtitle: Text('${lesson.durationMinutes} mins • ${lesson.type.toUpperCase()}'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/course/$courseId/lesson/${lesson.id}'),
    );
  }
}
