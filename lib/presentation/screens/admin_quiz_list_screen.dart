import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';

class AdminQuizListScreen extends StatelessWidget {
  final String courseId;

  const AdminQuizListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final courseRepo = context.watch<CourseRepository>();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Manage Quizzes',
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Fix Empty Quizzes',
            onPressed: () async {
              await courseRepo.deleteEmptyQuizzes(courseId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleaned up empty quizzes!'), backgroundColor: Colors.green),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/admin/course/$courseId/quiz/form'),
          ),
        ],
      ),
      body: StreamBuilder<List<QuizModel>>(
        stream: courseRepo.streamQuizzes(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(child: Text('No quizzes created yet. Tap + to add one.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                child: ListTile(
                  title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${quiz.questionCount} Questions • ${quiz.totalMarks} Marks • ${quiz.timeLimitMinutes} mins'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(quiz.isPublished ? 'Open' : 'Draft'),
                        backgroundColor: quiz.isPublished ? Colors.green.shade100 : Colors.orange.shade100,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () async {
                          await courseRepo.deleteQuiz(courseId, quiz.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () => context.push('/admin/course/$courseId/quiz/${quiz.id}/edit'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
