import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/course_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';

class StudentQuizListScreen extends StatelessWidget {
  const StudentQuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseRepo = context.watch<CourseRepository>();
    final authRepo = context.watch<AuthRepository>();
    final userId = authRepo.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Assessments'),
        body: Center(child: Text('Please log in to view quizzes.')),
      );
    }

    return Scaffold(
      appBar: const AppAppBar(title: 'Assessments & Quizzes', showBack: false),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: courseRepo.streamUserEnrollments(userId),
        builder: (context, enrollmentSnap) {
          final enrollments = enrollmentSnap.data ?? [];
          if (enrollments.isEmpty) {
            return const Center(child: Text('You are not enrolled in any courses yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              return StreamBuilder<List<QuizModel>>(
                stream: courseRepo.streamQuizzes(enrollment.courseId),
                builder: (context, quizSnap) {
                  final quizzes = quizSnap.data ?? [];
                  if (quizzes.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...quizzes.map((quiz) => Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                            child: ListTile(
                              title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${quiz.questionCount} Questions • ${quiz.totalMarks} Marks • ${quiz.timeLimitMinutes} mins'),
                              trailing: ElevatedButton(
                                onPressed: () => context.push('/quiz/${quiz.courseId}'),
                                child: const Text('Start'),
                              ),
                            ),
                          )),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
