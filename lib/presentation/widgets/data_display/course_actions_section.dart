import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/course_model.dart';
import '../../../data/repositories/course_repository.dart';

class CourseActionsSection extends StatelessWidget {
  final CourseModel course;
  final String? userId;
  final bool isAdmin;

  const CourseActionsSection({
    super.key,
    required this.course,
    required this.userId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Admin Course Controls', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spaceMd),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: () => context.push('/admin/course/${course.id}/quizzes'),
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('Manage Quizzes & Questions'),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: () async {
                final courseRepo = context.read<CourseRepository>();
                await courseRepo.togglePublishCourse(course.id, !course.isPublished);
              },
              icon: Icon(course.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              label: Text(course.isPublished ? 'Unpublish Course' : 'Publish Course'),
            ),
          ],
        ),
      );
    }

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final courseRepo = context.watch<CourseRepository>();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: StreamBuilder<EnrollmentModel?>(
        stream: courseRepo.streamEnrollment(userId!, course.id),
        builder: (context, enrollmentSnap) {
          final enrollment = enrollmentSnap.data;
          if (enrollment != null) {
            return Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => context.push('/quiz/${course.id}'),
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('Take Assessment Quiz'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enrolled! Progress: ${(enrollment.progressPercent * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            );
          }

          return ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              await courseRepo.enrollInCourse(userId!, course.id);
            },
            child: const Text('Enroll Now'),
          );
        },
      ),
    );
  }
}
