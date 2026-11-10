import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../common/app_button.dart';

class CourseActionsSection extends StatelessWidget {
  final CourseModel course;
  final String? userId;
  final bool isAdmin;

  const CourseActionsSection({
    super.key,
    required this.course,
    required this.userId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isAdmin) {
      return Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Admin Course Controls',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Manage Quizzes & Questions',
              icon: Icons.quiz_rounded,
              onPressed: () => context.push('/admin/course/${course.id}/quizzes'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: course.isPublished ? 'Unpublish Course' : 'Publish Course',
              icon: course.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () async {
                final courseRepo = context.read<CourseRepository>();
                await courseRepo.togglePublishCourse(course.id, !course.isPublished);
              },
            ),
          ],
        ),
      );
    }

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final courseRepo = context.watch<CourseRepository>();

    return StreamBuilder<EnrollmentModel?>(
      stream: courseRepo.streamEnrollment(userId!, course.id),
      builder: (context, enrollmentSnap) {
        final enrollment = enrollmentSnap.data;
        if (enrollment != null) {
          final progressPct = (enrollment.progressPercent * 100).toInt();
          return Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enrolled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$progressPct% Completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (course.quizCount > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Take Assessment Quiz',
                    icon: Icons.quiz_rounded,
                    onPressed: () => context.push('/quiz/${course.id}'),
                  ),
                ],
              ],
            ),
          );
        }

        return AppButton(
          text: 'Enroll Now',
          icon: Icons.school_rounded,
          onPressed: () async {
            await courseRepo.enrollInCourse(userId!, course.id);
          },
        );
      },
    );
  }
}
