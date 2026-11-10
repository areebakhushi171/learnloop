import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/section_header.dart';
import '../widgets/custom_widgets.dart';

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
    TextEditingController(),
    TextEditingController(),
  ];

  final Set<int> _correctIndexes = {};
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
        _correctIndexes.remove(index);
        final updatedSet = <int>{};
        for (var idx in _correctIndexes) {
          if (idx > index) {
            updatedSet.add(idx - 1);
          } else {
            updatedSet.add(idx);
          }
        }
        _correctIndexes.clear();
        _correctIndexes.addAll(updatedSet);
      });
    }
  }

  void _shuffleOptionsInEditor() {
    setState(() {
      final List<MapEntry<String, bool>> items = [];
      for (int i = 0; i < _optionControllers.length; i++) {
        items.add(MapEntry(_optionControllers[i].text, _correctIndexes.contains(i)));
      }
      items.shuffle();

      _correctIndexes.clear();
      for (int i = 0; i < items.length; i++) {
        _optionControllers[i].text = items[i].key;
        if (items[i].value) {
          _correctIndexes.add(i);
        }
      }
    });
  }

  void _toggleCorrectIndex(int index) {
    setState(() {
      if (_selectedType == QuestionType.mcq || _selectedType == QuestionType.trueFalse) {
        _correctIndexes.clear();
        _correctIndexes.add(index);
      } else if (_selectedType == QuestionType.multiSelect) {
        if (_correctIndexes.contains(index)) {
          _correctIndexes.remove(index);
        } else {
          _correctIndexes.add(index);
        }
      }
    });
  }

  Future<void> _saveQuestion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedType != QuestionType.shortAnswer && _selectedType != QuestionType.longAnswer && _correctIndexes.isEmpty) {
      SnackbarUtils.showError(context, 'Select The Correct Answer!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final courseRepo = context.read<CourseRepository>();
      final options = _selectedType == QuestionType.trueFalse
          ? ['True', 'False']
          : _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      final question = QuizQuestionModel(
        id: widget.questionId ?? '',
        type: _selectedType,
        text: _textController.text.trim(),
        options: options,
        correctIndexes: _correctIndexes.toList()..sort(),
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
      SnackbarUtils.showError(context, 'Error saving question: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCorrectLabelsPreview() {
    if (_correctIndexes.isEmpty) return 'None Selected (Save Blocked)';
    final labels = _correctIndexes.map((i) {
      final letter = String.fromCharCode(65 + i);
      final text = i < _optionControllers.length ? _optionControllers[i].text : '';
      return text.isNotEmpty ? '$letter ($text)' : letter;
    }).join(', ');
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppAppBar(title: widget.questionId == null ? 'Add Question' : 'Edit Question'),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<QuestionType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Question Type'),
                items: QuestionType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _correctIndexes.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _textController, label: 'Question Text', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _marksController, label: 'Marks', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _explanationController, label: 'Explanation'),
              const SizedBox(height: AppSpacing.lg),

              if (_selectedType == QuestionType.mcq || _selectedType == QuestionType.multiSelect) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(title: 'Options'),
                    TextButton.icon(
                      onPressed: _shuffleOptionsInEditor,
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: const Text('Shuffle'),
                    ),
                  ],
                ),
                if (_correctIndexes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('Select The Correct Answer', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_optionControllers.length, (idx) {
                  final isCorrect = _correctIndexes.contains(idx);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: isCorrect ? AppColors.success : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                        width: isCorrect ? 2 : 1,
                      ),
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.1)
                          : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isCorrect ? AppColors.success : Colors.grey,
                          ),
                          onPressed: () => _toggleCorrectIndex(idx),
                        ),
                        Expanded(
                          child: AppTextField(
                            controller: _optionControllers[idx],
                            label: 'Option ${String.fromCharCode(65 + idx)}${isCorrect ? " (Correct)" : ""}',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                            onPressed: () => _removeOption(idx),
                          ),
                      ],
                    ),
                  );
                }),
                if (_optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Option'),
                  ),
              ],

              if (_selectedType == QuestionType.trueFalse) ...[
                const SectionHeader(title: 'Correct Answer'),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('True')),
                    ButtonSegment(value: 1, label: Text('False')),
                  ],
                  selected: _correctIndexes,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _correctIndexes.clear();
                      _correctIndexes.addAll(newSelection);
                    });
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

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
                    const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      _textController.text.isEmpty ? 'Question Text Preview' : _textController.text,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Correct Answer: ${_getCorrectLabelsPreview()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _correctIndexes.isNotEmpty ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(text: 'Save Question', onPressed: _isLoading ? null : _saveQuestion, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
