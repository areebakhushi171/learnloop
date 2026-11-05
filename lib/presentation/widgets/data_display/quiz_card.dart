import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/course_repository.dart';

enum QuizCardMode { student, admin }

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final QuizCardMode mode;
  final String courseId;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.mode,
    required this.courseId,
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
                  TextButton.icon(
                    onPressed: () => context.push('/admin/course/$courseId/quizzes'),
                    icon: const Icon(Icons.analytics_rounded, size: 16),
                    label: const Text('Submissions'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: ListTile(
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${quiz.questionCount} Questions • ${quiz.totalMarks} Marks • ${quiz.timeLimitMinutes} mins'),
        trailing: ElevatedButton(
          onPressed: () => context.push('/quiz/$courseId'),
          child: const Text('Start Quiz'),
        ),
      ),
    );
  }
}
