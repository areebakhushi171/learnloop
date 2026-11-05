import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';

class AdminQuestionManagerScreen extends StatelessWidget {
  final String courseId;
  final String quizId;

  const AdminQuestionManagerScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('No questions added yet. Tap + to add questions.'));
          }

          final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);

          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Questions: ${questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Marks: $totalMarks', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Type: ${q.type.name.toUpperCase()} • Marks: ${q.marks}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () async {
                            await courseRepo.deleteQuestion(courseId, quizId, q.id);
                          },
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
