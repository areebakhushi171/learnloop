import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/admin_quiz_builder_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/section_header.dart';
import '../widgets/states/empty_state.dart';

class AdminQuizBuilderScreen extends StatelessWidget {
  final String courseId;
  final String? quizId;

  const AdminQuizBuilderScreen({
    super.key,
    required this.courseId,
    this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminQuizBuilderViewModel(
        courseRepository: context.read<CourseRepository>(),
        courseId: courseId,
        existingQuizId: quizId,
      ),
      child: const _QuizBuilderContent(),
    );
  }
}

class _QuizBuilderContent extends StatefulWidget {
  const _QuizBuilderContent();

  @override
  State<_QuizBuilderContent> createState() => _QuizBuilderContentState();
}

class _QuizBuilderContentState extends State<_QuizBuilderContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _passingMarksController = TextEditingController(text: '70');
  final _timeLimitController = TextEditingController(text: '30');
  final _maxAttemptsController = TextEditingController(text: '1');
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _passingMarksController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  void _syncDetailsToViewModel() {
    final viewModel = context.read<AdminQuizBuilderViewModel>();
    viewModel.setQuizDetails(
      title: _titleController.text,
      description: _descController.text,
      instructions: _instructionsController.text,
      passingMarks: int.tryParse(_passingMarksController.text) ?? 70,
      timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 30,
      maxAttempts: int.tryParse(_maxAttemptsController.text) ?? 1,
      isPublished: _isPublished,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<AdminQuizBuilderViewModel>();
    final authRepo = context.watch<AuthRepository>();
    final userId = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppAppBar(
        title: viewModel.existingQuizId == null ? 'Quiz Builder' : 'Edit Quiz Builder',
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '1. Details'),
                    Tab(text: '2. Questions'),
                    Tab(text: '3. Review & Save'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Step 1: Details
                      SingleChildScrollView(
                        padding: AppSpacing.screenPadding,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _titleController,
                                label: 'Quiz Title',
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(controller: _descController, label: 'Description'),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(controller: _instructionsController, label: 'Instructions'),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _passingMarksController,
                                label: 'Passing Marks',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _timeLimitController,
                                label: 'Time Limit (Minutes)',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _maxAttemptsController,
                                label: 'Max Attempts',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SwitchListTile(
                                title: const Text('Publish Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                                value: _isPublished,
                                onChanged: (val) {
                                  setState(() => _isPublished = val);
                                  _syncDetailsToViewModel();
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                text: 'Next: Add Questions',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    _syncDetailsToViewModel();
                                    _tabController.animateTo(1);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 2: Questions Draft
                      Column(
                        children: [
                          Container(
                            padding: AppSpacing.cardPadding,
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Questions: ${viewModel.questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Total Marks: ${viewModel.totalMarks}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: viewModel.questions.isEmpty
                                ? Center(
                                    child: EmptyState(
                                      icon: Icons.quiz_outlined,
                                      message: 'No questions added yet.',
                                      buttonText: 'Add Question',
                                      onButtonPressed: () => _openAddQuestionDialog(context),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: AppSpacing.screenPadding,
                                    itemCount: viewModel.questions.length,
                                    itemBuilder: (context, index) {
                                      final q = viewModel.questions[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                        padding: AppSpacing.cardPadding,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                          borderRadius: AppRadius.radiusLg,
                                          border: Border.all(
                                            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(child: Text('${index + 1}')),
                                          title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${q.type.name.toUpperCase()} • ${q.marks} Marks • Options: ${q.options.length}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                            onPressed: () => viewModel.removeQuestion(index),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: AppSpacing.screenPadding,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openAddQuestionDialog(context),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Question'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _syncDetailsToViewModel();
                                      _tabController.animateTo(2);
                                    },
                                    child: const Text('Review & Save'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Step 3: Review & Atomic Save
                      Padding(
                        padding: AppSpacing.screenPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                borderRadius: AppRadius.radiusLg,
                                border: Border.all(
                                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeader(title: 'Quiz Summary'),
                                  const Divider(),
                                  Text('Title: ${viewModel.title.isEmpty ? "(Not Set)" : viewModel.title}'),
                                  const SizedBox(height: 4),
                                  Text('Questions Count: ${viewModel.questions.length}'),
                                  const SizedBox(height: 4),
                                  Text('Total Marks: ${viewModel.totalMarks}'),
                                  const SizedBox(height: 4),
                                  Text('Passing Marks: ${viewModel.passingMarks}'),
                                  const SizedBox(height: 4),
                                  Text('Status: ${viewModel.isPublished ? "Published" : "Draft"}'),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (viewModel.questions.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.radiusLg,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Add At Least One Question To Save This Quiz',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            AppButton(
                              text: 'Save Quiz',
                              icon: Icons.check_circle_rounded,
                              onPressed: viewModel.canSave
                                  ? () async {
                                      final success = await viewModel.saveQuiz(createdByUserId: userId);
                                      if (success && context.mounted) {
                                        SnackbarUtils.showSuccess(context, 'Quiz saved successfully!');
                                        context.pop();
                                      }
                                    }
                                  : null,
                              isLoading: viewModel.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _openAddQuestionDialog(BuildContext context) {
    final viewModel = context.read<AdminQuizBuilderViewModel>();
    final textController = TextEditingController();
    final marksController = TextEditingController(text: '1');
    final optionAController = TextEditingController();
    final optionBController = TextEditingController();
    final optionCController = TextEditingController();
    final optionDController = TextEditingController();
    int correctOptionIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Add 4-Option Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(controller: textController, label: 'Question Text'),
                  const SizedBox(height: 8),
                  AppTextField(controller: marksController, label: 'Marks', keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  const Text('Options (All 4 Required)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  AppTextField(controller: optionAController, label: 'Option A'),
                  const SizedBox(height: 6),
                  AppTextField(controller: optionBController, label: 'Option B'),
                  const SizedBox(height: 6),
                  AppTextField(controller: optionCController, label: 'Option C'),
                  const SizedBox(height: 6),
                  AppTextField(controller: optionDController, label: 'Option D'),
                  const SizedBox(height: 12),
                  const Text('Mark Correct Option', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('A')),
                      ButtonSegment(value: 1, label: Text('B')),
                      ButtonSegment(value: 2, label: Text('C')),
                      ButtonSegment(value: 3, label: Text('D')),
                    ],
                    selected: {correctOptionIndex},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() => correctOptionIndex = newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final text = textController.text.trim();
                  final optA = optionAController.text.trim();
                  final optB = optionBController.text.trim();
                  final optC = optionCController.text.trim();
                  final optD = optionDController.text.trim();

                  if (text.isEmpty || optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
                    SnackbarUtils.showError(dialogCtx, 'Please fill all 4 options!');
                    return;
                  }

                  final question = QuizQuestionModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: QuestionType.mcq,
                    text: text,
                    options: [optA, optB, optC, optD],
                    correctIndexes: [correctOptionIndex],
                    marks: int.tryParse(marksController.text.trim()) ?? 1,
                    explanation: '',
                    topic: 'General',
                    order: viewModel.questions.length,
                  );

                  viewModel.addQuestion(question);
                  Navigator.pop(ctx);
                },
                child: const Text('Add Question'),
              ),
            ],
          );
        },
      ),
    );
  }
}
