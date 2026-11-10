import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/common/app_text_field.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<LessonPlayerViewModel>();
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      appBar: const AppAppBar(title: 'Lesson Player'),
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
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Container
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: AppRadius.radiusLg,
                    boxShadow: AppTheme.softShadow(Colors.black, 0.2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppBadge(
                              label: '${currentLesson.durationMinutes} mins HD Video',
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              textColor: Colors.white,
                              icon: Icons.video_library_rounded,
                            ),
                            if (viewModel.isCompleted)
                              const AppBadge(
                                label: 'COMPLETED (+50 XP)',
                                backgroundColor: AppColors.success,
                                textColor: Colors.white,
                                icon: Icons.check_circle_rounded,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  currentLesson.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Lesson Content Card
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ),
                  child: Text(
                    currentLesson.markdownContent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Notes Section
                const SectionHeader(title: 'Personal Study Notes'),
                const SizedBox(height: AppSpacing.xs),
                AppTextField(
                  controller: _notesController,
                  label: '',
                  hint: 'Record key formulas, observations, or action items...',
                  maxLines: 4,
                  onChanged: viewModel.setNotes,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Action Button
                AppButton(
                  text: viewModel.isCompleted ? 'Completed (+50 XP)' : 'Complete & Claim 50 XP',
                  icon: viewModel.isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                  isLoading: viewModel.isMarkingComplete,
                  onPressed: () async {
                    if (user == null) return;
                    final ok = await viewModel.completeLesson(user.uid, lessons.length);
                    if (context.mounted && ok) {
                      SnackbarUtils.showSuccess(context, '+50 XP! Lesson marked as completed.');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
