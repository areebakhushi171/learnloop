import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/admin_quiz_builder_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';

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
                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _titleController,
                                label: 'Quiz Title',
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              AppTextField(controller: _descController, label: 'Description'),
                              const SizedBox(height: AppTheme.spaceMd),
                              AppTextField(controller: _instructionsController, label: 'Instructions'),
                              const SizedBox(height: AppTheme.spaceMd),
                              AppTextField(
                                controller: _passingMarksController,
                                label: 'Passing Marks',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              AppTextField(
                                controller: _timeLimitController,
                                label: 'Time Limit (Minutes)',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              AppTextField(
                                controller: _maxAttemptsController,
                                label: 'Max Attempts',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              SwitchListTile(
                                title: const Text('Publish Quiz'),
                                value: _isPublished,
                                onChanged: (val) {
                                  setState(() => _isPublished = val);
                                  _syncDetailsToViewModel();
                                },
                              ),
                              const SizedBox(height: AppTheme.spaceLg),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    _syncDetailsToViewModel();
                                    _tabController.animateTo(1);
                                  }
                                },
                                child: const Text('Next: Add Questions'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 2: Questions Draft
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            color: Theme.of(context).colorScheme.primaryContainer,
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
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        const Text('No questions added yet.'),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => _openAddQuestionDialog(context),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Question'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                                    itemCount: viewModel.questions.length,
                                    itemBuilder: (context, index) {
                                      final q = viewModel.questions[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                                        child: ListTile(
                                          leading: CircleAvatar(child: Text('${index + 1}')),
                                          title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                                          subtitle: Text('${q.type.name.toUpperCase()} • ${q.marks} Marks'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                            onPressed: () => viewModel.removeQuestion(index),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openAddQuestionDialog(context),
                                    icon: const Icon(Icons.add),
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
                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spaceLg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Quiz Summary', style: Theme.of(context).textTheme.titleLarge),
                                    const Divider(),
                                    Text('Title: ${viewModel.title.isEmpty ? "(Not Set)" : viewModel.title}'),
                                    Text('Questions Count: ${viewModel.questions.length}'),
                                    Text('Total Marks: ${viewModel.totalMarks}'),
                                    Text('Passing Marks: ${viewModel.passingMarks}'),
                                    Text('Status: ${viewModel.isPublished ? "Published" : "Draft"}'),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (viewModel.questions.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.amber.shade100,
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Add At Least One Question To Save This Quiz',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            AppButton(
                              text: 'Save Quiz',
                              onPressed: viewModel.canSave
                                  ? () async {
                                      final success = await viewModel.saveQuiz(createdByUserId: userId);
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Quiz saved successfully!'), backgroundColor: Colors.green),
                                        );
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
    final textController = TextEditingController();
    final marksController = TextEditingController(text: '1');
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Question to Draft'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: textController, label: 'Question Text'),
              const SizedBox(height: 8),
              AppTextField(controller: marksController, label: 'Marks', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              AppTextField(controller: option1Controller, label: 'Option A (Correct)'),
              const SizedBox(height: 8),
              AppTextField(controller: option2Controller, label: 'Option B'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isEmpty || option1Controller.text.trim().isEmpty || option2Controller.text.trim().isEmpty) return;

              final question = QuizQuestionModel(
                id: '',
                type: QuestionType.mcq,
                text: textController.text.trim(),
                options: [option1Controller.text.trim(), option2Controller.text.trim()],
                correctIndexes: [0],
                marks: int.tryParse(marksController.text.trim()) ?? 1,
                explanation: '',
                topic: 'General',
                order: 0,
              );

              context.read<AdminQuizBuilderViewModel>().addQuestion(question);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
