import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../custom_widgets.dart';

enum LessonTileMode { student, admin }

class LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final LessonTileMode mode;
  final String courseId;
  final VoidCallback? onEdit;
  final bool isCompleted;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.mode,
    required this.courseId,
    this.onEdit,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget tileContent = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.5)
                : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
                  : Text(
                      '${lesson.orderIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
          title: Text(
            lesson.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                lesson.type == 'video'
                    ? Icons.play_circle_outline_rounded
                    : Icons.article_outlined,
                size: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${lesson.durationMinutes} mins • ${lesson.type.toUpperCase()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          trailing: mode == LessonTileMode.admin
              ? IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onPressed: () {
                    ActionSheet.show(
                      context,
                      actions: [
                        if (onEdit != null)
                          ActionSheetItem(
                            icon: Icons.edit_rounded,
                            title: 'Edit Lesson',
                            onTap: onEdit!,
                          ),
                        ActionSheetItem(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete Lesson',
                          isDanger: true,
                          onTap: () async {
                            final courseRepo = context.read<CourseRepository>();
                            await courseRepo.deleteLesson(courseId, lesson.id);
                          },
                        ),
                      ],
                    );
                  },
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap: mode == LessonTileMode.student
              ? () => context.push('/course/$courseId/lesson/${lesson.id}')
              : onEdit,
        ),
      ),
    );

    if (mode == LessonTileMode.admin) {
      return SwipeActionTile(
        onEdit: onEdit,
        onDelete: () async {
          final courseRepo = context.read<CourseRepository>();
          await courseRepo.deleteLesson(courseId, lesson.id);
        },
        deleteTitle: 'Delete Lesson',
        deleteMessage: 'Are you sure you want to delete "${lesson.title}"?',
        child: tileContent,
      );
    }

    return tileContent;
  }
}
