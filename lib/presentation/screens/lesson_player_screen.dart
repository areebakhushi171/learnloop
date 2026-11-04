import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/lesson_player_viewmodel.dart';

class LessonPlayerScreen extends StatelessWidget {
  final String courseId;
  final String lessonId;

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LessonPlayerViewModel(
        courseRepository: context.read<CourseRepository>(),
        authRepository: context.read<AuthRepository>(),
        courseId: courseId,
        lessonId: lessonId,
      ),
      child: const _LessonPlayerContent(),
    );
  }
}

class _LessonPlayerContent extends StatefulWidget {
  const _LessonPlayerContent();

  @override
  State<_LessonPlayerContent> createState() => _LessonPlayerContentState();
}

class _LessonPlayerContentState extends State<_LessonPlayerContent> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<LessonPlayerViewModel>();
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Player'),
      ),
      body: StreamBuilder<List<LessonModel>>(
        stream: viewModel.lessonsStream,
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? [];
          final currentLesson = lessons.firstWhere(
            (l) => l.id == viewModel.lessonId,
            orElse: () => LessonModel(
              id: viewModel.lessonId,
              courseId: viewModel.courseId,
              title: 'Study Session',
              description: '',
              orderIndex: 1,
              durationMinutes: 10,
              markdownContent: 'Reviewing lesson material...',
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white70),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Text(
                          '${currentLesson.durationMinutes} mins HD Video Lesson',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text(currentLesson.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  currentLesson.markdownContent,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.spaceXl),
                Text('Personal Study Notes', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceXs),
                TextField(
                  controller: _notesController,
                  onChanged: viewModel.setNotes,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Record key formulas, observations, or action items...',
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                ElevatedButton.icon(
                  onPressed: viewModel.isMarkingComplete
                      ? null
                      : () async {
                          if (user == null) return;
                          final ok = await viewModel.completeLesson(user.uid, lessons.length);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('+50 XP! Lesson marked as completed.'),
                                backgroundColor: AppSemanticColors.success,
                              ),
                            );
                          }
                        },
                  icon: viewModel.isMarkingComplete
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(viewModel.isCompleted ? 'Completed (+50 XP)' : 'Complete & Claim 50 XP'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
