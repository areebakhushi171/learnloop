import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';

class AdminQuestionEditorScreen extends StatefulWidget {
  final String courseId;
  final String quizId;
  final String? questionId;

  const AdminQuestionEditorScreen({
    super.key,
    required this.courseId,
    required this.quizId,
    this.questionId,
  });

  @override
  State<AdminQuestionEditorScreen> createState() => _AdminQuestionEditorScreenState();
}

class _AdminQuestionEditorScreenState extends State<AdminQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _marksController = TextEditingController(text: '1');
  final _explanationController = TextEditingController();
  final _topicController = TextEditingController(text: 'General');

  QuestionType _selectedType = QuestionType.mcq;
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _marksController.dispose();
    _explanationController.dispose();
    _topicController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() => _optionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index).dispose();
        if (_correctIndex >= _optionControllers.length) {
          _correctIndex = 0;
        }
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final courseRepo = context.read<CourseRepository>();
      final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      final question = QuizQuestionModel(
        id: widget.questionId ?? '',
        type: _selectedType,
        text: _textController.text.trim(),
        options: _selectedType == QuestionType.trueFalse ? ['True', 'False'] : options,
        correctIndexes: [_correctIndex],
        marks: int.tryParse(_marksController.text.trim()) ?? 1,
        explanation: _explanationController.text.trim(),
        topic: _topicController.text.trim(),
        order: 0,
      );

      await courseRepo.createOrUpdateQuestion(widget.courseId, widget.quizId, question);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving question: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: widget.questionId == null ? 'Add Question' : 'Edit Question'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<QuestionType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
                items: QuestionType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: AppTheme.spaceMd),
              AppTextField(controller: _textController, label: 'Question Text', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: AppTheme.spaceMd),
              AppTextField(controller: _marksController, label: 'Marks', keyboardType: TextInputType.number),
              const SizedBox(height: AppTheme.spaceMd),
              AppTextField(controller: _explanationController, label: 'Explanation'),
              const SizedBox(height: AppTheme.spaceLg),

              if (_selectedType == QuestionType.mcq || _selectedType == QuestionType.multiSelect) ...[
                Text('Options', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceSm),
                ...List.generate(_optionControllers.length, (idx) {
                  final isSelected = _correctIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                          ),
                          onPressed: () => setState(() => _correctIndex = idx),
                        ),
                        Expanded(
                          child: AppTextField(
                            controller: _optionControllers[idx],
                            label: 'Option ${String.fromCharCode(65 + idx)}',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeOption(idx),
                          ),
                      ],
                    ),
                  );
                }),
                if (_optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
              ],

              const SizedBox(height: AppTheme.spaceXl),
              AppButton(text: 'Save Question', onPressed: _isLoading ? null : _saveQuestion, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
