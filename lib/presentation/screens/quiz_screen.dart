import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_utils.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../presentation/widgets/states/empty_state.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/quiz_viewmodel.dart';

class QuizScreen extends StatelessWidget {
  final String courseId;

  const QuizScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizViewModel(
        courseRepository: context.read<CourseRepository>(),
        authRepository: context.read<AuthRepository>(),
        courseId: courseId,
      ),
      child: const _QuizContent(),
    );
  }
}

class _QuizContent extends StatefulWidget {
  const _QuizContent();

  @override
  State<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<_QuizContent> {
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final viewModel = context.read<QuizViewModel>();
    if (viewModel.isFinished) return true;

    final confirm = await DialogUtils.showConfirm(
      context,
      title: 'Leave Quiz?',
      message: 'Are you sure you want to leave? Your progress in this attempt will be lost.',
      confirmText: 'Leave',
      isDanger: true,
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<QuizViewModel>();
    final user = context.watch<AuthViewModel>().user;

    if (viewModel.isFinished && viewModel.isPassed && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      _confettiController.play();
    }

    if (viewModel.isLoading || viewModel.quiz == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Loading Quiz'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final quiz = viewModel.quiz!;

    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppAppBar(title: quiz.title),
        body: Center(
          child: EmptyState(
            icon: Icons.quiz_outlined,
            message: 'No questions available for this quiz yet.',
            buttonText: 'Go Back',
            onButtonPressed: () => context.pop(),
          ),
        ),
      );
    }

    final minutes = viewModel.remainingSeconds ~/ 60;
    final seconds = (viewModel.remainingSeconds % 60).toString().padLeft(2, '0');
    final isTimerLow = viewModel.remainingSeconds < 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: quiz.title,
          onBackPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AppBadge(
                  label: '$minutes:$seconds',
                  backgroundColor: isTimerLow
                      ? AppColors.error.withValues(alpha: 0.15)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: isTimerLow ? AppColors.error : theme.colorScheme.primary,
                  icon: Icons.timer_outlined,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: AppSpacing.screenPadding,
              child: viewModel.isFinished
                  ? _buildResultView(theme, viewModel)
                  : _buildQuestionView(theme, viewModel, user?.uid),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionView(
    ThemeData theme,
    QuizViewModel viewModel,
    String? userId,
  ) {
    final quiz = viewModel.quiz!;
    final isDark = theme.brightness == Brightness.dark;
    final index = viewModel.currentQuestionIndex.clamp(0, quiz.questions.length - 1);
    final question = quiz.questions[index];
    final displayedSelectedOption = viewModel.selectedAnswers[index];

    final optionOrder = viewModel.optionOrders[question.id] ?? List.generate(question.options.length, (i) => i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(
          percent: (index + 1) / quiz.questions.length,
          height: 6,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Question ${index + 1} of ${quiz.questions.length}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          question.questionText,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Expanded(
          child: ListView.separated(
            itemCount: optionOrder.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, displayedIdx) {
              final originalIdx = optionOrder[displayedIdx];
              final optionText = question.options[originalIdx];
              final isChosen = displayedSelectedOption == displayedIdx;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => viewModel.selectAnswer(index, displayedIdx),
                  borderRadius: AppRadius.radiusLg,
                  child: Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: isChosen
                            ? theme.colorScheme.primary
                            : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                        width: isChosen ? 2 : 1,
                      ),
                      color: isChosen
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isChosen
                              ? theme.colorScheme.primary
                              : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight),
                          child: Text(
                            String.fromCharCode(65 + displayedIdx),
                            style: TextStyle(
                              color: isChosen
                                  ? Colors.white
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            optionText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isChosen ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          text: index == quiz.questions.length - 1 ? 'Finish Quiz' : 'Next Question',
          icon: index == quiz.questions.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
          onPressed: () async {
            if (index < quiz.questions.length - 1) {
              viewModel.nextQuestion();
            } else {
              await viewModel.finishQuiz(userId);
            }
          },
        ),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme, QuizViewModel viewModel) {
    final quiz = viewModel.quiz!;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (viewModel.isPassed ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                viewModel.isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                size: 64,
                color: viewModel.isPassed ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Score: ${viewModel.scorePercent.toInt()}%',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              viewModel.isPassed
                  ? 'Outstanding! You mastered this module (+${viewModel.earnedXp} XP).'
                  : 'Keep practicing! Review topics and retry.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Review List
            Text(
              'Review Answers',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(quiz.questions.length, (idx) {
              final q = quiz.questions[idx];
              final optionOrder = viewModel.optionOrders[q.id] ?? List.generate(q.options.length, (i) => i);
              final displayedSelectedIdx = viewModel.selectedAnswers[idx];

              final originalSelectedIdx = (displayedSelectedIdx != null && displayedSelectedIdx < optionOrder.length)
                  ? optionOrder[displayedSelectedIdx]
                  : -1;

              final isCorrect = q.correctIndexes.contains(originalSelectedIdx);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q${idx + 1}: ${q.text}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Your Answer: ${originalSelectedIdx >= 0 && originalSelectedIdx < q.options.length ? q.options[originalSelectedIdx] : "None"}',
                      style: TextStyle(
                        color: isCorrect ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Correct Answer: ${q.correctIndexes.map((i) => q.options[i]).join(', ')}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Explanation: ${q.explanation}', style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Back to Course',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
