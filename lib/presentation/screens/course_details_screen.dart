import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/course_details_viewmodel.dart';
import '../widgets/custom_widgets.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final courseRepo = context.read<CourseRepository>();

    return ChangeNotifierProvider(
      create: (_) => CourseDetailsViewModel(courseRepo, courseId),
      child: const _CourseDetailsContent(),
    );
  }
}

class _CourseDetailsContent extends StatelessWidget {
  const _CourseDetailsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CourseDetailsViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.user;

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final course = viewModel.course;
    if (course == null) {
      return Scaffold(
        body: Center(
          child: AppErrorWidget(
            errorMessage: viewModel.errorMessage ?? 'Course not found',
            onRetry: viewModel.loadCourse,
          ),
        ),
      );
    }

    final enrollmentStream = user != null ? viewModel.streamEnrollment(user.uid) : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'course_image_${course.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(course.thumbnailUrl, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text(course.category)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${course.rating} (${course.totalRatings})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(course.title, style: theme.textTheme.headlineLarge),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Instructor: ${course.instructorName}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(course.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.spaceLg),

                  // Enrollment Section
                  StreamBuilder<EnrollmentModel?>(
                    stream: enrollmentStream,
                    builder: (context, enrollSnap) {
                      final enrollment = enrollSnap.data;
                      final isEnrolled = enrollment != null;

                      if (isEnrolled) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('${(enrollment.progressPercent * 100).toInt()}%'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: enrollment.progressPercent,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/quiz/${course.id}'),
                              icon: const Icon(Icons.quiz_rounded),
                              label: const Text('Take Course Quiz'),
                            ),
                          ],
                        );
                      }

                      return ElevatedButton.icon(
                        onPressed: viewModel.isEnrolling
                            ? null
                            : () async {
                                if (user == null) return;
                                final ok = await viewModel.enroll(user.uid);
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully enrolled!'),
                                      backgroundColor: AppSemanticColors.success,
                                    ),
                                  );
                                }
                              },
                        icon: viewModel.isEnrolling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('Enroll in Course'),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  Text('Curriculum Syllabus', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
          StreamBuilder<List<LessonModel>>(
            stream: viewModel.lessonsStream,
            builder: (context, lessonSnap) {
              final lessons = lessonSnap.data ?? [];
              if (lessons.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spaceLg),
                    child: Text('Curriculum is being prepared.'),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = lessons[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${lesson.orderIndex}')),
                      title: Text(lesson.title),
                      subtitle: Text('${lesson.durationMinutes} min read'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        context.go('/course/${course.id}/lesson/${lesson.id}');
                      },
                    );
                  },
                  childCount: lessons.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
