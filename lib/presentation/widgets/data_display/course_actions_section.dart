import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../presentation/screens/certificate_screen.dart';
import '../../../viewmodels/auth_viewmodel.dart';
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

          return StreamBuilder<List<QuizModel>>(
            stream: courseRepo.streamQuizzes(course.id),
            builder: (context, quizSnap) {
              final quizzes = (quizSnap.data ?? []).where((q) => q.isPublished).toList();

              return StreamBuilder<List<QuizAttemptModel>>(
                stream: courseRepo.streamUserQuizAttempts(userId!, course.id),
                builder: (context, attemptSnap) {
                  final attempts = attemptSnap.data ?? [];

                  final allLessonsDone = enrollment.completedLessonIds.length >= course.totalLessons || enrollment.progressPercent >= 1.0;
                  final allQuizzesPassed = quizzes.isEmpty || quizzes.every((q) {
                    final qAttempts = attempts.where((a) => a.quizId == q.id).toList();
                    return qAttempts.any((a) => a.passed);
                  });

                  final isFullyPassed = allLessonsDone && allQuizzesPassed;
                  final isApproved = enrollment.adminApproved;

                  final unpassedQuizzesWithRetakes = quizzes.where((q) {
                    final qAttempts = attempts.where((a) => a.quizId == q.id).toList();
                    final passed = qAttempts.any((a) => a.passed);
                    return !passed && qAttempts.length < 2; // Allows 1 retake (max 2 total attempts)
                  }).toList();

                  final unpassedQuizzesExhausted = quizzes.where((q) {
                    final qAttempts = attempts.where((a) => a.quizId == q.id).toList();
                    final passed = qAttempts.any((a) => a.passed);
                    return !passed && qAttempts.length >= 2; // Used 1 retake chance
                  }).toList();

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
                            Row(
                              children: [
                                Icon(
                                  isFullyPassed ? Icons.check_circle_rounded : Icons.school_rounded,
                                  color: isFullyPassed ? AppColors.success : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFullyPassed ? 'Course Completed' : 'Enrolled',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFullyPassed ? AppColors.success : theme.colorScheme.primary,
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
                        const SizedBox(height: AppSpacing.md),

                        if (isFullyPassed) ...[
                          if (isApproved) ...[
                            AppButton(
                              text: 'View / Download Certificate',
                              icon: Icons.workspace_premium_rounded,
                              onPressed: () {
                                final authVM = context.read<AuthViewModel>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CertificateScreen(
                                      courseTitle: course.title,
                                      studentName: authVM.user?.displayName ?? 'Student',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: AppRadius.radiusMd,
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All lectures & quizzes passed! Waiting for Admin Certificate Approval.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else if (unpassedQuizzesWithRetakes.isNotEmpty) ...[
                          AppButton(
                            text: attempts.isEmpty ? 'Take Assessment Quiz' : 'Retake Assessment Quiz (1 Retake Left)',
                            icon: Icons.quiz_rounded,
                            onPressed: () => context.push('/quiz/${course.id}/${unpassedQuizzesWithRetakes.first.id}'),
                          ),
                        ] else if (unpassedQuizzesExhausted.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: AppRadius.radiusMd,
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Assessment Failed (Max Retakes Used)',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You have used your 1 retake attempt for this course\'s quiz. Please review course lectures.',
                                  style: TextStyle(fontSize: 12, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
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
