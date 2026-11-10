import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/enrollment_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/data_display/quiz_card.dart';
import '../widgets/states/empty_state.dart';

class StudentQuizListScreen extends StatelessWidget {
  const StudentQuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseRepo = context.watch<CourseRepository>();
    final authRepo = context.watch<AuthRepository>();
    final userId = authRepo.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Assessments', showBack: false),
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Please log in to view quizzes.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppAppBar(title: 'Assessments & Quizzes', showBack: false),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: courseRepo.streamUserEnrollments(userId),
        builder: (context, enrollmentSnap) {
          final enrollments = enrollmentSnap.data ?? [];
          if (enrollments.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.assignment_outlined,
                message: 'You are not enrolled in any courses yet.',
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('student_quiz_list_scroll_key'),
            padding: AppSpacing.screenPadding,
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
                      ...quizzes.map((quiz) => QuizCard(
                            quiz: quiz,
                            mode: QuizCardMode.student,
                            courseId: quiz.courseId,
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
