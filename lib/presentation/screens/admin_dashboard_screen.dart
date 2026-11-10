import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/user_model.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/common/app_text_field.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../presentation/widgets/states/empty_state.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final navigationDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Courses',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded),
        label: 'Students',
      ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded),
        label: 'Analytics',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    final bodyViews = [
      _AdminOverviewTab(onNavigateToTab: (idx) {
        setState(() => _selectedIndex = idx);
      }),
      const _AdminCourseManagementTab(),
      const _AdminStudentManagementTab(),
      const _AdminAnalyticsTab(),
      const _AdminProfileTab(),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                ),
              ),
              destinations: navigationDestinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon ?? d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: SafeArea(child: bodyViews[_selectedIndex])),
          ],
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: navigationDestinations,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: bodyViews,
        ),
      ),
    );
  }
}

// --- TAB 0: MAIN DASHBOARD OVERVIEW ---

class _AdminOverviewTab extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const _AdminOverviewTab({required this.onNavigateToTab});

  void _showCourseDialog(BuildContext context, {CourseModel? courseToEdit}) {
    final titleController = TextEditingController(text: courseToEdit?.title ?? '');
    final descController = TextEditingController(text: courseToEdit?.description ?? '');
    final categoryController = TextEditingController(text: courseToEdit?.category ?? 'Computer Science');
    final instructorController = TextEditingController(text: courseToEdit?.instructorName ?? 'Lead Instructor');
    final thumbnailController = TextEditingController(
      text: courseToEdit?.thumbnailUrl ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
    );
    final durationController = TextEditingController(text: '${courseToEdit?.durationMinutes ?? 90}');
    String level = courseToEdit?.level ?? 'Beginner';
    bool isFeatured = courseToEdit?.isFeatured ?? false;

    AppBottomSheet.show(
      context: context,
      title: courseToEdit == null ? 'Create New Course' : 'Edit Course',
      child: Column(
        children: [
          AppTextField(controller: titleController, label: 'Course Title'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: descController, label: 'Description', maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: categoryController, label: 'Category'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: instructorController, label: 'Instructor Name'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: thumbnailController, label: 'Thumbnail Image URL'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: durationController,
            label: 'Duration (Minutes)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Difficulty Level'),
                    items: const [
                      DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => level = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    title: const Text('Featured Course', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: isFeatured,
                    onChanged: (val) => setDialogState(() => isFeatured = val),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Save Course',
            icon: Icons.check_circle_rounded,
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final course = CourseModel(
                id: courseToEdit?.id ?? '',
                title: titleController.text.trim(),
                description: descController.text.trim(),
                category: categoryController.text.trim(),
                instructorName: instructorController.text.trim(),
                thumbnailUrl: thumbnailController.text.trim(),
                durationMinutes: int.tryParse(durationController.text.trim()) ?? 90,
                totalLessons: courseToEdit?.totalLessons ?? 0,
                level: level,
                isFeatured: isFeatured,
                createdAt: courseToEdit?.createdAt ?? DateTime.now(),
              );

              final adminVM = context.read<AdminViewModel>();
              final ok = await adminVM.saveCourse(course);
              if (context.mounted) {
                Navigator.pop(context);
                if (ok) {
                  SnackbarUtils.showSuccess(context, 'Course saved successfully!');
                } else {
                  SnackbarUtils.showError(context, 'Failed to save course.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final adminVM = context.watch<AdminViewModel>();
    final user = authVM.user;

    return StreamBuilder<List<CourseModel>>(
      stream: adminVM.coursesStream,
      builder: (context, courseSnap) {
        final courses = courseSnap.data ?? [];

        return StreamBuilder<List<UserModel>>(
          stream: adminVM.studentsStream,
          builder: (context, studentSnap) {
            final students = studentSnap.data ?? [];

            return StreamBuilder<List<EnrollmentModel>>(
              stream: adminVM.globalEnrollmentsStream,
              builder: (context, enrollSnap) {
                final enrollments = enrollSnap.data ?? [];
                final completedEnrollments = enrollments.where((e) => e.progressPercent >= 1.0).length;
                final inProgressEnrollments = enrollments.length - completedEnrollments;

                return StreamBuilder<List<LessonModel>>(
                  stream: adminVM.globalLessonsStream,
                  builder: (context, lessonSnap) {
                    final globalLessons = lessonSnap.data ?? [];

                    return SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Banner
                          Container(
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              gradient: AppGradients.heroHeader(
                                theme.colorScheme.primary,
                                AppColors.accentLight,
                              ),
                              borderRadius: AppRadius.radiusXxl,
                              boxShadow: AppTheme.softShadow(Colors.black, 0.1),
                            ),
                            child: Row(
                              children: [
                                AppAvatar(
                                  name: user?.displayName ?? 'Administrator',
                                  radius: 28,
                                  imageUrl: user?.photoUrl,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user?.displayName ?? 'Administrator',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const AppBadge(
                                            label: 'ADMIN',
                                            backgroundColor: Colors.white,
                                            textColor: Colors.black,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                                  tooltip: 'Sign Out',
                                  onPressed: () async {
                                    final confirm = await DialogUtils.showConfirm(
                                      context,
                                      title: 'Sign Out',
                                      message: 'Are you sure you want to sign out?',
                                      confirmText: 'Sign Out',
                                      isDanger: true,
                                    );
                                    if (confirm == true && context.mounted) {
                                      await authVM.signOut();
                                      if (context.mounted) {
                                        context.go('/auth');
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Control Center Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('LMS Control Center', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 140,
                                height: 38,
                                child: AppButton(
                                  text: 'New Course',
                                  icon: Icons.add_rounded,
                                  onPressed: () => _showCourseDialog(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Real-Time Metrics Grid
                          GridView.count(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.35,
                            children: [
                              StatCard(
                                title: 'Registered Students',
                                value: '${students.length}',
                                icon: Icons.people_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              StatCard(
                                title: 'Total Courses',
                                value: '${courses.length}',
                                icon: Icons.menu_book_rounded,
                                color: AppColors.xpGold,
                              ),
                              StatCard(
                                title: 'Total Lectures',
                                value: '${globalLessons.length}',
                                icon: Icons.play_lesson_rounded,
                                color: AppColors.accentLight,
                              ),
                              StatCard(
                                title: 'Total Enrollments',
                                value: '${enrollments.length}',
                                icon: Icons.assignment_turned_in_rounded,
                                color: AppColors.success,
                              ),
                              StatCard(
                                title: 'Completed',
                                value: '$completedEnrollments',
                                icon: Icons.verified_rounded,
                                color: AppColors.secondaryLight,
                              ),
                              StatCard(
                                title: 'Active Studies',
                                value: '$inProgressEnrollments',
                                icon: Icons.trending_up_rounded,
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Course Catalog Preview Section
                          SectionHeader(
                            title: 'Course Catalog (${courses.length})',
                            actionText: 'Manage All Courses',
                            onActionPressed: () => onNavigateToTab(1),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (courses.isEmpty)
                            const EmptyState(
                              icon: Icons.school_outlined,
                              message: 'No courses found in database.',
                            )
                          else
                            ...courses.map((course) {
                              return SwipeActionTile(
                                onEdit: () => _showCourseDialog(context, courseToEdit: course),
                                onDelete: () async {
                                  await adminVM.deleteCourse(course.id);
                                },
                                deleteTitle: 'Delete Course',
                                deleteMessage: 'Are you sure you want to delete "${course.title}"?',
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(course.thumbnailUrl),
                                      ),
                                      title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${course.category} • ${course.level} • ${course.totalLessons} Lessons'),
                                      trailing: const Icon(Icons.chevron_right_rounded),
                                      onTap: () => context.go('/course/${course.id}'),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: AppSpacing.xl),

                          // Students Roster Preview Section
                          SectionHeader(
                            title: 'Registered Students (${students.length})',
                            actionText: 'View All Students',
                            onActionPressed: () => onNavigateToTab(2),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (students.isEmpty)
                            const EmptyState(
                              icon: Icons.people_outline_rounded,
                              message: 'No registered student records found.',
                            )
                          else
                            ...students.take(5).map((student) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                                    leading: AppAvatar(name: student.displayName),
                                    title: Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${student.email} • Streak: ${student.streakDays}d • ${student.totalXp} XP'),
                                    trailing: const Icon(Icons.chevron_right_rounded),
                                    onTap: () => onNavigateToTab(2),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- TAB 1: COURSE & LECTURE MANAGEMENT ---

class _AdminCourseManagementTab extends StatelessWidget {
  const _AdminCourseManagementTab();

  void _showCourseDialog(BuildContext context, {CourseModel? courseToEdit}) {
    final titleController = TextEditingController(text: courseToEdit?.title ?? '');
    final descController = TextEditingController(text: courseToEdit?.description ?? '');
    final categoryController = TextEditingController(text: courseToEdit?.category ?? 'Computer Science');
    final instructorController = TextEditingController(text: courseToEdit?.instructorName ?? 'Lead Instructor');
    final thumbnailController = TextEditingController(
      text: courseToEdit?.thumbnailUrl ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
    );
    final durationController = TextEditingController(text: '${courseToEdit?.durationMinutes ?? 90}');
    String level = courseToEdit?.level ?? 'Beginner';
    bool isFeatured = courseToEdit?.isFeatured ?? false;

    AppBottomSheet.show(
      context: context,
      title: courseToEdit == null ? 'Create New Course' : 'Edit Course',
      child: Column(
        children: [
          AppTextField(controller: titleController, label: 'Course Title'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: descController, label: 'Description', maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: categoryController, label: 'Category'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: instructorController, label: 'Instructor Name'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: thumbnailController, label: 'Thumbnail Image URL'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: durationController,
            label: 'Duration (Minutes)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Difficulty Level'),
                    items: const [
                      DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => level = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    title: const Text('Featured Course', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: isFeatured,
                    onChanged: (val) => setDialogState(() => isFeatured = val),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Save Course',
            icon: Icons.check_circle_rounded,
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final course = CourseModel(
                id: courseToEdit?.id ?? '',
                title: titleController.text.trim(),
                description: descController.text.trim(),
                category: categoryController.text.trim(),
                instructorName: instructorController.text.trim(),
                thumbnailUrl: thumbnailController.text.trim(),
                durationMinutes: int.tryParse(durationController.text.trim()) ?? 90,
                totalLessons: courseToEdit?.totalLessons ?? 0,
                level: level,
                isFeatured: isFeatured,
                createdAt: courseToEdit?.createdAt ?? DateTime.now(),
              );

              final adminVM = context.read<AdminViewModel>();
              final ok = await adminVM.saveCourse(course);
              if (context.mounted) {
                Navigator.pop(context);
                if (ok) {
                  SnackbarUtils.showSuccess(context, 'Course saved successfully!');
                } else {
                  SnackbarUtils.showError(context, 'Failed to save course.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLectureDialog(BuildContext context, String courseId, {LessonModel? lessonToEdit}) {
    final titleController = TextEditingController(text: lessonToEdit?.title ?? '');
    final descController = TextEditingController(text: lessonToEdit?.description ?? '');
    final videoUrlController = TextEditingController(text: lessonToEdit?.videoUrl ?? '');
    final durationController = TextEditingController(text: '${lessonToEdit?.durationMinutes ?? 10}');
    final orderController = TextEditingController(text: '${lessonToEdit?.orderIndex ?? 0}');

    AppBottomSheet.show(
      context: context,
      title: lessonToEdit == null ? 'Add Lecture' : 'Edit Lecture',
      child: Column(
        children: [
          AppTextField(controller: titleController, label: 'Lecture Title'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: descController, label: 'Description', maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: videoUrlController, label: 'Video URL'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: durationController, label: 'Duration (Minutes)', keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: orderController, label: 'Order Index', keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Save Lecture',
            icon: Icons.check_circle_rounded,
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final lesson = LessonModel(
                id: lessonToEdit?.id ?? '',
                courseId: courseId,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                orderIndex: int.tryParse(orderController.text.trim()) ?? 0,
                durationMinutes: int.tryParse(durationController.text.trim()) ?? 10,
                videoUrl: videoUrlController.text.trim().isEmpty ? null : videoUrlController.text.trim(),
                markdownContent: 'Interactive study material for ${titleController.text.trim()}.',
              );

              final adminVM = context.read<AdminViewModel>();
              final ok = await adminVM.saveLesson(courseId, lesson);
              if (context.mounted) {
                Navigator.pop(context);
                if (ok) {
                  SnackbarUtils.showSuccess(context, 'Lecture saved!');
                } else {
                  SnackbarUtils.showError(context, 'Failed to save lecture.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminVM = context.watch<AdminViewModel>();

    return StreamBuilder<List<CourseModel>>(
      stream: adminVM.coursesStream,
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];

        return Scaffold(
          appBar: AppAppBar(
            title: 'Course & Lecture Management',
            showBack: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add Course',
                onPressed: () => _showCourseDialog(context),
              ),
            ],
          ),
          body: courses.isEmpty
              ? EmptyState(
                  icon: Icons.school_outlined,
                  message: 'No courses available',
                  buttonText: 'Create First Course',
                  onButtonPressed: () => _showCourseDialog(context),
                )
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return SwipeActionTile(
                      onEdit: () => _showCourseDialog(context, courseToEdit: course),
                      onDelete: () async {
                        await adminVM.deleteCourse(course.id);
                      },
                      deleteTitle: 'Delete Course',
                      deleteMessage: 'Are you sure you want to delete "${course.title}"?',
                      child: Material(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLg,
                          side: BorderSide(
                            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(course.thumbnailUrl),
                          ),
                          title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${course.category} • ${course.level} • ${course.totalLessons} Lessons'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Lectures List', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => context.push('/admin/course/${course.id}/quizzes'),
                                        icon: const Icon(Icons.quiz_rounded, size: 16),
                                        label: const Text('Quizzes'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _showLectureDialog(context, course.id),
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Add Lecture'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            StreamBuilder<List<LessonModel>>(
                              stream: adminVM.streamLessons(course.id),
                              builder: (context, lessonSnap) {
                                final lessons = lessonSnap.data ?? [];
                                if (lessons.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('No lectures added yet.', style: TextStyle(color: Colors.grey)),
                                  );
                                }
                                return Column(
                                  children: lessons.map((lesson) {
                                    return SwipeActionTile(
                                      onEdit: () => _showLectureDialog(context, course.id, lessonToEdit: lesson),
                                      onDelete: () => adminVM.deleteLesson(course.id, lesson.id),
                                      deleteTitle: 'Delete Lecture',
                                      deleteMessage: 'Are you sure you want to delete "${lesson.title}"?',
                                      child: ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 12,
                                          child: Text('${lesson.orderIndex + 1}', style: const TextStyle(fontSize: 10)),
                                        ),
                                        title: Text(lesson.title),
                                        subtitle: Text('${lesson.durationMinutes} mins ${lesson.videoUrl != null ? "• Video" : ""}'),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// --- TAB 2: STUDENT MANAGEMENT ---

class _AdminStudentManagementTab extends StatefulWidget {
  const _AdminStudentManagementTab();

  @override
  State<_AdminStudentManagementTab> createState() => _AdminStudentManagementTabState();
}

class _AdminStudentManagementTabState extends State<_AdminStudentManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAssignCourseDialog(BuildContext context, UserModel student) {
    final adminVM = context.read<AdminViewModel>();

    AppBottomSheet.show(
      context: context,
      title: 'Enrollments for ${student.displayName}',
      child: StreamBuilder<List<CourseModel>>(
        stream: adminVM.coursesStream,
        builder: (context, snapshot) {
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Text('No courses available.');
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, idx) {
              final course = courses[idx];
              return StreamBuilder<List<EnrollmentModel>>(
                stream: adminVM.streamStudentEnrollments(student.uid),
                builder: (context, enrollSnap) {
                  final enrollments = enrollSnap.data ?? [];
                  final enrollment = enrollments.where((e) => e.courseId == course.id).firstOrNull;
                  final isEnrolled = enrollment != null;
                  final isCompleted = isEnrolled && enrollment.progressPercent >= 1.0;

                  return ListTile(
                    title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEnrolled
                              ? 'Progress: ${(enrollment.progressPercent * 100).toInt()}% • ${enrollment.completedLessonIds.length}/${course.totalLessons} lessons'
                              : 'Not enrolled',
                        ),
                        if (isCompleted) ...[
                          const SizedBox(height: 2),
                          Text(
                            enrollment.adminApproved ? '✨ Certificate Approved' : '⏳ Pending Certificate Approval',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: enrollment.adminApproved ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isEnrolled
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCompleted) ...[
                                TextButton(
                                  onPressed: () async {
                                    await adminVM.approveCourseCompletion(student.uid, course.id, !enrollment.adminApproved);
                                  },
                                  child: Text(
                                    enrollment.adminApproved ? 'Unapprove' : 'Approve',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: enrollment.adminApproved ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              OutlinedButton(
                                onPressed: () async {
                                  await adminVM.removeCourseAssignment(student.uid, course.id);
                                },
                                child: const Text('Revoke'),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              await adminVM.assignCourse(student.uid, course.id);
                            },
                            child: const Text('Assign'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminVM = context.watch<AdminViewModel>();

    return StreamBuilder<List<UserModel>>(
      stream: adminVM.studentsStream,
      builder: (context, snapshot) {
        final allStudents = snapshot.data ?? [];
        final filteredStudents = allStudents.where((s) {
          final query = _searchQuery.toLowerCase().trim();
          return query.isEmpty ||
              s.displayName.toLowerCase().contains(query) ||
              s.email.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppAppBar(
            title: 'Registered Students (${allStudents.length})',
            showBack: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding,
                child: AppTextField(
                  controller: _searchController,
                  label: '',
                  hint: 'Search student by name or email...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: filteredStudents.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_off_rounded,
                        message: 'No students match your query.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: filteredStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return SwipeActionTile(
                            onEdit: () => _showAssignCourseDialog(context, student),
                            onDelete: () async {
                              await adminVM.deleteStudent(student.uid);
                            },
                            deleteTitle: 'Delete Student',
                            deleteMessage: 'Are you sure you want to delete ${student.displayName}?',
                            child: Material(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.radiusLg,
                                side: BorderSide(
                                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                                ),
                              ),
                              child: Padding(
                                padding: AppSpacing.cardPadding,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: AppAvatar(name: student.displayName),
                                  title: Row(
                                    children: [
                                      Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      AppBadge(
                                        label: '${student.totalXp} XP',
                                        backgroundColor: AppColors.xpGold.withValues(alpha: 0.15),
                                        textColor: AppColors.xpGold,
                                      ),
                                    ],
                                  ),
                                  subtitle: Text('${student.email}\nStreak: ${student.streakDays} days'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onPressed: () {
                                      ActionSheet.show(
                                        context,
                                        actions: [
                                          ActionSheetItem(
                                            icon: Icons.assignment_add,
                                            title: 'Manage Enrollments',
                                            onTap: () => _showAssignCourseDialog(context, student),
                                          ),
                                          ActionSheetItem(
                                            icon: Icons.delete_outline_rounded,
                                            title: 'Delete Record',
                                            isDanger: true,
                                            onTap: () async {
                                              await adminVM.deleteStudent(student.uid);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- TAB 3: REPORTS & ANALYTICS ---

class _AdminAnalyticsTab extends StatelessWidget {
  const _AdminAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminVM = context.watch<AdminViewModel>();

    return StreamBuilder<List<CourseModel>>(
      stream: adminVM.coursesStream,
      builder: (context, courseSnap) {
        final courses = courseSnap.data ?? [];
        final totalLessons = courses.fold<int>(0, (sum, c) => sum + c.totalLessons);

        return StreamBuilder<List<UserModel>>(
          stream: adminVM.studentsStream,
          builder: (context, studentSnap) {
            final students = studentSnap.data ?? [];

            return StreamBuilder<List<EnrollmentModel>>(
              stream: adminVM.globalEnrollmentsStream,
              builder: (context, enrollSnap) {
                final enrollments = enrollSnap.data ?? [];
                final completedEnrollments = enrollments.where((e) => e.isCompleted || e.progressPercent >= 1.0).length;
                final activeEnrollments = enrollments.where((e) => !e.isCompleted && e.progressPercent < 1.0).length;
                final avgProgress = enrollments.isEmpty
                    ? 0.0
                    : (enrollments.fold<double>(0.0, (sum, e) => sum + e.progressPercent) / enrollments.length) * 100;

                return Scaffold(
                  appBar: const AppAppBar(title: 'Reports & Real Analytics', showBack: false),
                  body: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Metrics Summary Card
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Student Engagement & Progress',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('${students.length} Total Students', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Overall Average Progress', style: theme.textTheme.bodyMedium),
                                  Text('${avgProgress.toStringAsFixed(1)}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ProgressBar(
                                percent: (avgProgress / 100).clamp(0.0, 1.0),
                                height: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Real Stats Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Registered Students',
                                value: '${students.length}',
                                icon: Icons.people_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatCard(
                                title: 'Active Enrollments',
                                value: '$activeEnrollments',
                                icon: Icons.school_rounded,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Completed Courses',
                                value: '$completedEnrollments',
                                icon: Icons.workspace_premium_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatCard(
                                title: 'Total Lessons',
                                value: '$totalLessons',
                                icon: Icons.menu_book_rounded,
                                color: AppColors.xpGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        const SectionHeader(title: 'Course Catalog Overview'),
                        const SizedBox(height: AppSpacing.md),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Active Courses', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${courses.length} Courses', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text('Categories: ${courses.map((c) => c.category).toSet().join(', ')}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- TAB 4: ADMIN PROFILE & SETTINGS ---

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthViewModel>().user;
    final themeVM = context.watch<ThemeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Admin Profile', showBack: false),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  AppAvatar(
                    name: user?.displayName ?? 'Admin',
                    radius: 48,
                    imageUrl: user?.photoUrl,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user?.displayName ?? 'Admin', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: AppSpacing.sm),
                const AppBadge(
                  label: 'ADMIN',
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                ),
              ],
            ),
            Text(user?.email ?? '', style: theme.textTheme.bodySmall),
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
                  const SectionHeader(title: 'Accent Color Palette'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: AppAccentPalette.values.map((palette) {
                      final isSelected = palette == themeVM.accentPalette;
                      return GestureDetector(
                        onTap: () => themeVM.setAccentPalette(palette),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: palette.primary.withValues(alpha: 0.5), blurRadius: 10)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Appearance Mode', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  DropdownButton<ThemeMode>(
                    value: themeVM.themeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        themeVM.setThemeMode(mode);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppButton(
              text: 'Sign Out',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              onPressed: () async {
                final confirm = await DialogUtils.showConfirm(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out?',
                  confirmText: 'Sign Out',
                  isDanger: true,
                );
                if (confirm == true && context.mounted) {
                  await profileVM.signOut();
                  if (context.mounted) {
                    context.read<AuthViewModel>().signOut();
                    context.go('/auth');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
