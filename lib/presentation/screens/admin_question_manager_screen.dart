import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/states/empty_state.dart';

class AdminQuestionManagerScreen extends StatelessWidget {
  final String courseId;
  final String quizId;

  const AdminQuestionManagerScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  String _formatCorrectAnswerBadge(QuizQuestionModel q) {
    if (q.type == QuestionType.shortAnswer || q.type == QuestionType.longAnswer) {
      return 'Written Answer';
    }
    if (q.correctIndexes.isEmpty) {
      return 'Needs Correct Answer';
    }
    final labels = q.correctIndexes.map((i) => String.fromCharCode(65 + i)).join(', ');
    return 'Correct: $labels';
  }

  String? _checkPositionBalance(List<QuizQuestionModel> questions) {
    final mcqQuestions = questions.where((q) => q.type == QuestionType.mcq && q.correctIndexes.isNotEmpty).toList();
    if (mcqQuestions.length < 3) return null;

    final Map<int, int> positionCounts = {};
    for (var q in mcqQuestions) {
      final pos = q.correctIndexes.first;
      positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
    }

    for (var entry in positionCounts.entries) {
      if (entry.value / mcqQuestions.length > 0.5) {
        final optionLetter = String.fromCharCode(65 + entry.key);
        return 'Most Correct Answers Are Option $optionLetter. Consider Varying Positions.';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courseRepo = context.watch<CourseRepository>();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Question Manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/admin/course/$courseId/quiz/$quizId/question/new'),
          ),
        ],
      ),
      body: StreamBuilder<List<QuizQuestionModel>>(
        stream: courseRepo.streamQuestions(courseId, quizId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.quiz_outlined,
                message: 'No questions added yet.',
                buttonText: 'Add First Question',
                onButtonPressed: () => context.push('/admin/course/$courseId/quiz/$quizId/question/new'),
              ),
            );
          }

          final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);
          final balanceWarning = _checkPositionBalance(questions);

          return Column(
            children: [
              Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Questions: ${questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Total Marks: $totalMarks', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (balanceWarning != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                balanceWarning,
                                style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: AppSpacing.screenPadding,
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final hasCorrectAnswer = q.correctIndexes.isNotEmpty || q.type == QuestionType.shortAnswer || q.type == QuestionType.longAnswer;

                    return SwipeActionTile(
                      onEdit: () => context.push('/admin/course/$courseId/quiz/$quizId/question/new'),
                      onDelete: () async {
                        await courseRepo.deleteQuestion(courseId, quizId, q.id);
                      },
                      deleteTitle: 'Delete Question',
                      deleteMessage: 'Are you sure you want to delete this question?',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Material(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusLg,
                            side: BorderSide(
                              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                            ),
                          ),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(child: Text('${index + 1}')),
                              title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${q.type.name.toUpperCase()} • Marks: ${q.marks}'),
                                  const SizedBox(height: 4),
                                  AppBadge(
                                    label: _formatCorrectAnswerBadge(q),
                                    backgroundColor: hasCorrectAnswer
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : AppColors.error.withValues(alpha: 0.15),
                                    textColor: hasCorrectAnswer ? AppColors.success : AppColors.error,
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/admin/course/$courseId/quiz/$quizId/question/new'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
