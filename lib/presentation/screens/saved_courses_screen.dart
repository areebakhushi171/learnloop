import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';

class SavedCoursesScreen extends StatelessWidget {
  const SavedCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    final courseRepo = context.watch<CourseRepository>();
    final user = authRepo.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Saved Courses'),
        body: Center(child: Text('Please log in to view bookmarks.')),
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
            return const Center(child: Text('No bookmarked courses yet.'));
          }

          return StreamBuilder<List<CourseModel>>(
            stream: courseRepo.streamBookmarkedCourses(bookmarkedIds),
            builder: (context, courseSnap) {
              final courses = courseSnap.data ?? [];
              if (courses.isEmpty) {
                return const Center(child: Text('No bookmarked courses found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(course.thumbnailUrl, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${course.category} • ${course.level}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/course/${course.id}'),
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
