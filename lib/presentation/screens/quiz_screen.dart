import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_utils.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';

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
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No questions available for this quiz yet.', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                child: Text(
                  '${viewModel.remainingSeconds ~/ 60}:${(viewModel.remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
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
    if (quiz.questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final index = viewModel.currentQuestionIndex.clamp(0, quiz.questions.length - 1);
    final question = quiz.questions[index];
    final selectedOption = viewModel.selectedAnswers[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (index + 1) / quiz.questions.length,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          'Question ${index + 1} of ${quiz.questions.length}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(question.questionText, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spaceLg),
        ...List.generate(question.options.length, (idx) {
          final isChosen = selectedOption == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: InkWell(
              onTap: () => viewModel.selectAnswer(index, idx),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isChosen ? theme.colorScheme.primary : theme.colorScheme.outline,
                    width: isChosen ? 2 : 1,
                  ),
                  color: isChosen ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isChosen ? theme.colorScheme.primary : Colors.grey.shade300,
                      child: Text(
                        String.fromCharCode(65 + idx),
                        style: TextStyle(
                          color: isChosen ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(child: Text(question.options[idx])),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        ElevatedButton(
          onPressed: selectedOption == null
              ? null
              : () {
                  if (index < quiz.questions.length - 1) {
                    viewModel.nextQuestion();
                  } else {
                    viewModel.finishQuiz(userId);
                  }
                },
          child: Text(
            index == quiz.questions.length - 1
                ? 'Finish Quiz'
                : 'Next Question',
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme, QuizViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            viewModel.isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
            size: 80,
            color: viewModel.isPassed ? Colors.amber : Colors.orange,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text('Score: ${viewModel.scorePercent}%', style: theme.textTheme.displayMedium),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            viewModel.isPassed
                ? 'Outstanding! You mastered this module (+${viewModel.earnedXp} XP).'
                : 'Keep practicing! Review topics and retry.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.space2xl),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Course'),
          ),
        ],
      ),
    );
  }
}
