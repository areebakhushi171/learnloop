import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/data_display/course_actions_section.dart';
import '../widgets/data_display/lesson_tile.dart';
import '../widgets/data_display/quiz_card.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final courseRepo = context.watch<CourseRepository>();
    final authViewModel = context.watch<AuthViewModel>();
    final userId = authViewModel.user?.uid;
    final isAdmin = authViewModel.isAdmin;

    return Scaffold(
      body: FutureBuilder<CourseModel?>(
        future: courseRepo.getCourseById(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              appBar: AppAppBar(title: 'Course Details'),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final course = snapshot.data;
          if (course == null) {
            return const Scaffold(
              appBar: AppAppBar(title: 'Course Details'),
              body: Center(child: Text('Course not found.')),
            );
          }

          return CustomScrollView(
            key: PageStorageKey('course_details_$courseId'),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: 'Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(isAdmin ? RouteNames.adminDashboard : RouteNames.home);
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  background: Image.network(
                    course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
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
                              Text('${course.rating} (${course.totalRatings} ratings)', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      Text('About Course', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spaceSm),
                      Text(course.description, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppTheme.spaceLg),
                      Text('Syllabus / Lessons', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spaceSm),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<LessonModel>>(
                stream: courseRepo.streamLessons(courseId),
                builder: (context, lessonSnap) {
                  final lessons = lessonSnap.data ?? [];
                  if (lessons.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No lessons available yet.')),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = lessons[index];
                        return LessonTile(
                          lesson: lesson,
                          mode: isAdmin ? LessonTileMode.admin : LessonTileMode.student,
                          courseId: courseId,
                        );
                      },
                      childCount: lessons.length,
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spaceMd),
                      Text('Quizzes & Assessments', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spaceSm),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<QuizModel>>(
                stream: courseRepo.streamQuizzes(courseId),
                builder: (context, quizSnap) {
                  final quizzes = quizSnap.data ?? [];
                  if (quizzes.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No quizzes available.')),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quiz = quizzes[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                          child: QuizCard(
                            quiz: quiz,
                            mode: isAdmin ? QuizCardMode.admin : QuizCardMode.student,
                            courseId: courseId,
                          ),
                        );
                      },
                      childCount: quizzes.length,
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: CourseActionsSection(
                  course: course,
                  userId: userId,
                  isAdmin: isAdmin,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
