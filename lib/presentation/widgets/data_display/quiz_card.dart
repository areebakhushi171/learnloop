import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/course_repository.dart';

enum QuizCardMode { student, admin }

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final QuizCardMode mode;
  final String courseId;
  final List<QuizAttemptModel> quizAttempts;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.mode,
    required this.courseId,
    this.quizAttempts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (mode == QuizCardMode.admin) {
      return Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(quiz.isPublished ? 'Open' : 'Draft'),
                    backgroundColor: quiz.isPublished ? Colors.green.shade100 : Colors.orange.shade100,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                '${quiz.questionCount} Questions • ${quiz.totalMarks} Marks • ${quiz.timeLimitMinutes} mins',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/admin/course/$courseId/quiz/${quiz.id}/edit'),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () async {
                      final courseRepo = context.read<CourseRepository>();
                      await courseRepo.deleteQuiz(courseId, quiz.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Student Mode
    final isPassed = quizAttempts.any((a) => a.passed);
    final bestAttempt = quizAttempts.isNotEmpty
        ? (List<QuizAttemptModel>.from(quizAttempts)..sort((a, b) => b.score.compareTo(a.score))).first
        : null;
    final attemptCount = quizAttempts.length;
    final canRetake = !isPassed && attemptCount < 2; // Exactly 1 retake allowed (max 2 total attempts)

    Widget trailingWidget;
    if (isPassed) {
      trailingWidget = Chip(
        label: const Text('Passed'),
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
      );
    } else if (canRetake) {
      trailingWidget = ElevatedButton(
        onPressed: () => context.push('/quiz/$courseId/${quiz.id}'),
        child: Text(attemptCount == 0 ? 'Start Quiz' : 'Retake Quiz'),
      );
    } else {
      trailingWidget = Chip(
        label: const Text('Failed'),
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: ListTile(
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${quiz.questionCount} Questions • ${quiz.totalMarks} Marks • ${quiz.timeLimitMinutes} mins'),
            if (bestAttempt != null) ...[
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Icon(
                    isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 16,
                    color: isPassed ? AppColors.success : AppColors.error,
                  ),
                  Text(
                    isPassed
                        ? 'Passed • Score: ${bestAttempt.scorePercent}%'
                        : (attemptCount >= 2
                            ? 'Failed (${bestAttempt.scorePercent}%) • Max 1 Retake Reached'
                            : 'Failed (${bestAttempt.scorePercent}%) • 1 Retake Chance Left'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isPassed ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: trailingWidget,
      ),
    );
  }
}
