import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/data_display/quiz_card.dart';
import '../widgets/states/empty_state.dart';

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
                SnackbarUtils.showSuccess(context, 'Cleaned up empty quizzes!');
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
            return Center(
              child: EmptyState(
                icon: Icons.quiz_outlined,
                message: 'No quizzes created yet. Tap + to add one.',
                buttonText: 'Create Quiz',
                onButtonPressed: () => context.push('/admin/course/$courseId/quiz/form'),
              ),
            );
          }

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return QuizCard(
                quiz: quiz,
                mode: QuizCardMode.admin,
                courseId: courseId,
              );
            },
          );
        },
      ),
    );
  }
}
