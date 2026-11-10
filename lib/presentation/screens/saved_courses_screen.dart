import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/states/empty_state.dart';

class SavedCoursesScreen extends StatelessWidget {
  const SavedCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authRepo = context.watch<AuthRepository>();
    final courseRepo = context.watch<CourseRepository>();
    final user = authRepo.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Saved Courses'),
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Please log in to view bookmarks.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppAppBar(title: 'Saved Courses', showBack: false),
      body: StreamBuilder(
        key: const PageStorageKey('saved_courses_scroll_key'),
        stream: authRepo.streamUserProfile(user.uid),
        builder: (context, userSnap) {
          final profile = userSnap.data;
          final bookmarkedIds = profile?.bookmarkedCourseIds ?? [];

          if (bookmarkedIds.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.bookmark_border_rounded,
                message: 'No bookmarked courses yet.',
              ),
            );
          }

          return StreamBuilder<List<CourseModel>>(
            stream: courseRepo.streamBookmarkedCourses(bookmarkedIds),
            builder: (context, courseSnap) {
              final courses = courseSnap.data ?? [];
              if (courses.isEmpty) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    message: 'No bookmarked courses found.',
                  ),
                );
              }

              return ListView.builder(
                padding: AppSpacing.screenPadding,
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Material(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusLg,
                        side: BorderSide(
                          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: AppRadius.radiusMd,
                          child: Image.network(course.thumbnailUrl, width: 56, height: 56, fit: BoxFit.cover),
                        ),
                        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${course.category} • ${course.level}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/course/${course.id}'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
