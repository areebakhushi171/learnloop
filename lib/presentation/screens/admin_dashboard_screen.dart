import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../widgets/custom_widgets.dart';

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
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white),
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

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(courseToEdit == null ? 'Create New Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(labelText: 'Instructor Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnailController,
                  decoration: const InputDecoration(labelText: 'Thumbnail Image URL'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                ),
                const SizedBox(height: 12),
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
                        SwitchListTile(
                          title: const Text('Featured Course'),
                          value: isFeatured,
                          onChanged: (val) => setDialogState(() => isFeatured = val),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Course saved!' : 'Failed to save course.'),
                      backgroundColor: ok ? AppSemanticColors.success : AppSemanticColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Course'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Banner
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user?.displayName ?? 'Administrator',
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded),
                                  tooltip: 'Sign Out',
                                  onPressed: () async {
                                    await authVM.signOut();
                                    if (context.mounted) {
                                      context.go('/auth');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXl),

                          // Dashboard Metrics Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'LMS Control Center',
                                  style: theme.textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(110, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                onPressed: () => _showCourseDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Course'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Real-Time Metrics Grid
                          GridView.count(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: AppTheme.spaceMd,
                            mainAxisSpacing: AppTheme.spaceMd,
                            childAspectRatio: 1.25,
                            children: [
                              _MetricCard(
                                title: 'Registered Students',
                                value: '${students.length}',
                                icon: Icons.people_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              _MetricCard(
                                title: 'Total Courses',
                                value: '${courses.length}',
                                icon: Icons.menu_book_rounded,
                                color: AppSemanticColors.xpGold,
                              ),
                              _MetricCard(
                                title: 'Total Lectures',
                                value: '${globalLessons.length}',
                                icon: Icons.play_lesson_rounded,
                                color: Colors.purple,
                              ),
                              _MetricCard(
                                title: 'Total Enrollments',
                                value: '${enrollments.length}',
                                icon: Icons.assignment_turned_in_rounded,
                                color: AppSemanticColors.success,
                              ),
                              _MetricCard(
                                title: 'Completed Enrollments',
                                value: '$completedEnrollments',
                                icon: Icons.verified_rounded,
                                color: Colors.teal,
                              ),
                              _MetricCard(
                                title: 'Active Enrollments',
                                value: '$inProgressEnrollments',
                                icon: Icons.trending_up_rounded,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceXl),

                          // Course Catalog Preview Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Course Catalog (${courses.length})', style: theme.textTheme.titleMedium),
                              TextButton(
                                onPressed: () => onNavigateToTab(1),
                                child: const Text('Manage All Courses'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          if (courses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    const Text('No courses found in database. Create courses from the Courses tab.'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...courses.map((course) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(course.thumbnailUrl),
                                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  ),
                                  title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${course.category} • ${course.level} • ${course.totalLessons} Lessons'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showCourseDialog(context, courseToEdit: course),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Course'),
                                              content: Text('Are you sure you want to delete "${course.title}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true && context.mounted) {
                                            await adminVM.deleteCourse(course.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.go('/course/${course.id}'),
                                ),
                              );
                            }),
                          const SizedBox(height: AppTheme.spaceXl),

                          // Students Roster Preview Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Registered Students (${students.length})', style: theme.textTheme.titleMedium),
                              TextButton(
                                onPressed: () => onNavigateToTab(2),
                                child: const Text('View All Students'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          if (students.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No registered student records found.'),
                            )
                          else
                            ...students.take(5).map((student) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(student.displayName.isNotEmpty ? student.displayName[0].toUpperCase() : 'S'),
                                  ),
                                  title: Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${student.email} • Streak: ${student.streakDays}d • ${student.totalXp} XP'),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => onNavigateToTab(2),
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

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(courseToEdit == null ? 'Create New Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(labelText: 'Instructor Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnailController,
                  decoration: const InputDecoration(labelText: 'Thumbnail Image URL'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                ),
                const SizedBox(height: 12),
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
                        SwitchListTile(
                          title: const Text('Featured Course'),
                          value: isFeatured,
                          onChanged: (val) => setDialogState(() => isFeatured = val),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Course saved!' : 'Failed to save course.'),
                      backgroundColor: ok ? AppSemanticColors.success : AppSemanticColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Course'),
            ),
          ],
        );
      },
    );
  }

  void _showLectureDialog(BuildContext context, String courseId, {LessonModel? lessonToEdit}) {
    final titleController = TextEditingController(text: lessonToEdit?.title ?? '');
    final descController = TextEditingController(text: lessonToEdit?.description ?? '');
    final videoUrlController = TextEditingController(text: lessonToEdit?.videoUrl ?? '');
    final durationController = TextEditingController(text: '${lessonToEdit?.durationMinutes ?? 10}');
    final orderController = TextEditingController(text: '${lessonToEdit?.orderIndex ?? 0}');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(lessonToEdit == null ? 'Add Lecture' : 'Edit Lecture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Lecture Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description / Summary'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    hintText: 'https://commondatastorage.googleapis.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Order Index'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Lecture saved!' : 'Failed to save lecture.'),
                      backgroundColor: ok ? AppSemanticColors.success : AppSemanticColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Lecture'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminVM = context.watch<AdminViewModel>();

    return StreamBuilder<List<CourseModel>>(
      stream: adminVM.coursesStream,
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Course & Lecture Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                tooltip: 'Add Course',
                onPressed: () => _showCourseDialog(context),
              ),
            ],
          ),
          body: courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('No courses available', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCourseDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Course'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMd),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                        ),
                        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${course.category} • ${course.level} • ${course.totalLessons} Lessons'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showCourseDialog(context, courseToEdit: course),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Course'),
                                    content: Text('Are you sure you want to delete "${course.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await adminVM.deleteCourse(course.id);
                                }
                              },
                            ),
                          ],
                        ),
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
                                      icon: const Icon(Icons.add, size: 18),
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
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 12,
                                      child: Text('${lesson.orderIndex + 1}', style: const TextStyle(fontSize: 10)),
                                    ),
                                    title: Text(lesson.title),
                                    subtitle: Text('${lesson.durationMinutes} mins ${lesson.videoUrl != null ? "• Has Video" : ""}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () => _showLectureDialog(context, course.id, lessonToEdit: lesson),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                          onPressed: () => adminVM.deleteLesson(course.id, lesson.id),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
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

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Course Enrollments for ${student.displayName}'),
          content: StreamBuilder<List<CourseModel>>(
            stream: adminVM.coursesStream,
            builder: (context, snapshot) {
              final courses = snapshot.data ?? [];
              if (courses.isEmpty) {
                return const Text('No courses available.');
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: courses.length,
                  itemBuilder: (context, idx) {
                    final course = courses[idx];
                    return StreamBuilder<List<EnrollmentModel>>(
                      stream: adminVM.streamStudentEnrollments(student.uid),
                      builder: (context, enrollSnap) {
                        final enrollments = enrollSnap.data ?? [];
                        final enrollment = enrollments.where((e) => e.courseId == course.id).firstOrNull;
                        final isEnrolled = enrollment != null;

                        return ListTile(
                          title: Text(course.title),
                          subtitle: Text(
                            isEnrolled
                                ? 'Progress: ${(enrollment.progressPercent * 100).toInt()}% • Completed ${enrollment.completedLessonIds.length}/${course.totalLessons} lessons'
                                : 'Not enrolled',
                          ),
                          trailing: isEnrolled
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                                  onPressed: () async {
                                    await adminVM.removeCourseAssignment(student.uid, course.id);
                                  },
                                  child: const Text('Revoke'),
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
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          appBar: AppBar(
            title: Text('Registered Students (${allStudents.length})'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search student by name or email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(child: Text('No students match your query.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                        itemCount: filteredStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMd),
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(student.displayName.isNotEmpty ? student.displayName[0].toUpperCase() : 'S'),
                              ),
                              title: Row(
                                children: [
                                  Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text('${student.totalXp} XP'),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: AppSemanticColors.xpGold.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                              subtitle: Text('${student.email}\nStreak: ${student.streakDays} days'),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'assign') {
                                    _showAssignCourseDialog(context, student);
                                  } else if (val == 'delete') {
                                    await adminVM.deleteStudent(student.uid);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'assign',
                                    child: Row(
                                      children: [
                                        Icon(Icons.assignment_add, size: 20),
                                        SizedBox(width: 8),
                                        Text('Manage Enrollments'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Delete Student Record', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
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
    final homeViewModel = context.watch<HomeViewModel>();

    return StreamBuilder<List<CourseModel>>(
      stream: homeViewModel.coursesStream,
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final totalLessons = courses.fold<int>(0, (sum, c) => sum + c.totalLessons);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reports & Analytics', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppTheme.space2xs),
              Text(
                'Comprehensive overview of platform learning metrics and course activity',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceLg),

              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Course Catalog Coverage', style: theme.textTheme.titleMedium),
                        Text('${courses.length} Active Courses', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    LinearProgressIndicator(
                      value: courses.isEmpty ? 0.0 : (courses.length / 10).clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Lessons',
                      value: '$totalLessons',
                      icon: Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: _MetricCard(
                      title: 'Categories',
                      value: '${courses.map((c) => c.category).toSet().length}',
                      icon: Icons.category_rounded,
                      color: AppSemanticColors.xpGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXl),

              Text('Weekly Platform Activity Trends', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppTheme.spaceMd),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Text(days[val.toInt() % 7], style: const TextStyle(fontSize: 11));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      _makeGroupData(0, 45, theme.colorScheme.primary),
                      _makeGroupData(1, 60, theme.colorScheme.primary),
                      _makeGroupData(2, 80, theme.colorScheme.primary),
                      _makeGroupData(3, 75, theme.colorScheme.primary),
                      _makeGroupData(4, 90, theme.colorScheme.primary),
                      _makeGroupData(5, 50, theme.colorScheme.primary),
                      _makeGroupData(6, 65, theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

// --- TAB 4: ADMIN PROFILE & SETTINGS ---

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthViewModel>().user;
    final themeVM = context.watch<ThemeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.admin_panel_settings_rounded, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.verified_user_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user?.displayName ?? 'Admin', style: theme.textTheme.headlineMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(user?.email ?? '', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppTheme.space2xl),

          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accent Color Palette', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: AppAccentPalette.values.map((palette) {
                    final isSelected = palette == themeVM.accentPalette;
                    return GestureDetector(
                      onTap: () => themeVM.setAccentPalette(palette),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: palette.primary, blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          GlassContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appearance Mode', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Switch between light, dark or system theme', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
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
          const SizedBox(height: AppTheme.space2xl),

          OutlinedButton.icon(
            onPressed: () async {
              await profileVM.signOut();
              if (context.mounted) {
                context.read<AuthViewModel>().signOut();
                context.go('/auth');
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
