import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';

class AdminQuizFormScreen extends StatefulWidget {
  final String courseId;
  final String? quizId;

  const AdminQuizFormScreen({super.key, required this.courseId, this.quizId});

  @override
  State<AdminQuizFormScreen> createState() => _AdminQuizFormScreenState();
}

class _AdminQuizFormScreenState extends State<AdminQuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _passingMarksController = TextEditingController(text: '70');
  final _timeLimitController = TextEditingController(text: '30');
  final _maxAttemptsController = TextEditingController(text: '1');

  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _passingMarksController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz({bool redirectToQuestions = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final courseRepo = context.read<CourseRepository>();
      final authRepo = context.read<AuthRepository>();
      final userId = authRepo.currentUser?.uid ?? '';

      final quiz = QuizModel(
        id: widget.quizId ?? '',
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        instructions: _instructionsController.text.trim(),
        order: 0,
        totalMarks: 100,
        passingMarks: int.tryParse(_passingMarksController.text.trim()) ?? 70,
        timeLimitMinutes: int.tryParse(_timeLimitController.text.trim()) ?? 30,
        maxAttempts: int.tryParse(_maxAttemptsController.text.trim()) ?? 1,
        scoringAttempt: ScoringAttempt.best,
        gradingMode: GradingMode.auto,
        shuffleQuestions: false,
        shuffleOptions: false,
        showResultsMode: ShowResultsMode.immediately,
        allowExtensionRequests: true,
        isPublished: _isPublished,
        questionCount: 0,
        createdBy: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.quizId == null || widget.quizId!.isEmpty) {
        await courseRepo.createQuizWithQuestions(widget.courseId, quiz, []);
      } else {
        await courseRepo.updateQuizWithQuestions(widget.courseId, quiz, []);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: widget.quizId == null ? 'Create Quiz' : 'Edit Quiz'),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(controller: _titleController, label: 'Quiz Title', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _descController, label: 'Description'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _instructionsController, label: 'Instructions'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _passingMarksController, label: 'Passing Marks', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _timeLimitController, label: 'Time Limit (Minutes)', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _maxAttemptsController, label: 'Max Attempts', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Publish Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _isPublished,
                onChanged: (val) => setState(() => _isPublished = val),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Save And Add Questions',
                icon: Icons.check_circle_rounded,
                onPressed: _isLoading ? null : () => _saveQuiz(redirectToQuestions: true),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
