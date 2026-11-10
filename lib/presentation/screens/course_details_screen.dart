import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../presentation/widgets/data_display/course_actions_section.dart';
import '../../presentation/widgets/data_display/lesson_tile.dart';
import '../../presentation/widgets/data_display/quiz_card.dart';
import '../../presentation/widgets/states/empty_state.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            return Scaffold(
              appBar: const AppAppBar(title: 'Course Details'),
              body: Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  message: 'Course not found.',
                ),
              ),
            );
          }

          return CustomScrollView(
            key: PageStorageKey('course_details_$courseId'),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  ),
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
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        course.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppBadge(
                            label: course.category,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            textColor: theme.colorScheme.primary,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${course.rating} (${course.totalRatings} ratings)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const SectionHeader(title: 'About Course'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        course.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Syllabus & Lessons'),
                      const SizedBox(height: AppSpacing.xs),
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
                      child: EmptyState(
                        icon: Icons.menu_book_rounded,
                        message: 'No lessons available yet.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList(
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
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      SectionHeader(title: 'Quizzes & Assessments'),
                      SizedBox(height: AppSpacing.xs),
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
                      child: EmptyState(
                        icon: Icons.quiz_outlined,
                        message: 'No quizzes available for this course.',
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quiz = quizzes[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: CourseActionsSection(
                    course: course,
                    userId: userId,
                    isAdmin: isAdmin,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
