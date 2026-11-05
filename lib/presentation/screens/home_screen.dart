import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/custom_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = context.watch<AuthViewModel>();
    final homeViewModel = context.watch<HomeViewModel>();
    final courseRepo = context.watch<CourseRepository>();
    final user = authViewModel.user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: homeViewModel.refresh,
          child: CustomScrollView(
            key: const PageStorageKey('home_scroll_key'),
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${user?.displayName ?? "Learner"} 👋',
                            style: theme.textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Let's accomplish today's targets",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      AnimatedStreakFlame(streakDays: user?.streakDays ?? 1),
                    ],
                  ),
                ),
              ),

              // Continue Learning Banner
              if (user != null)
                SliverToBoxAdapter(
                  child: StreamBuilder<List<EnrollmentModel>>(
                    stream: courseRepo.streamUserEnrollments(user.uid),
                    builder: (context, snapshot) {
                      final enrollments = snapshot.data ?? [];
                      if (enrollments.isEmpty) return const SizedBox.shrink();

                      enrollments.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
                      final activeEnrollment = enrollments.first;

                      return FutureBuilder<CourseModel?>(
                        future: courseRepo.getCourseById(activeEnrollment.courseId),
                        builder: (context, courseSnap) {
                          final course = courseSnap.data;
                          if (course == null) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                            child: GlassContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'CONTINUE LEARNING',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(activeEnrollment.progressPercent * 100).toInt()}% Done',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(course.title, style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: activeEnrollment.progressPercent,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(140, 38),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      onPressed: () => context.push('/course/${course.id}'),
                                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                      label: const Text('Resume'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              // Search Bar
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    onChanged: homeViewModel.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search courses, categories, mentors...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              // Category Selector
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = AppConstants.categories[idx];
                      final isSelected = cat == homeViewModel.selectedCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => homeViewModel.setCategory(cat),
                      );
                    },
                  ),
                ),
              ),

              // Course Tabs Header
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                sliver: SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'All Courses'),
                      Tab(text: 'My Enrolled Courses'),
                    ],
                  ),
                ),
              ),

              // Tab Content Area
              StreamBuilder<List<CourseModel>>(
                stream: homeViewModel.coursesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const Padding(
                            padding: EdgeInsets.only(bottom: AppTheme.spaceMd),
                            child: ShimmerSkeletonCard(height: 120),
                          ),
                          childCount: 3,
                        ),
                      ),
                    );
                  }

                  final allCourses = snapshot.data ?? [];
                  if (allCourses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Courses Found',
                        description: 'Try adjusting filters or searching for another keyword.',
                        buttonText: 'Reset Filters',
                        onButtonPressed: () {
                          homeViewModel.setCategory('All');
                          homeViewModel.setSearchQuery('');
                        },
                      ),
                    );
                  }

                  return AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      if (_tabController.index == 1 && user != null) {
                        return StreamBuilder<List<EnrollmentModel>>(
                          stream: courseRepo.streamUserEnrollments(user.uid),
                          builder: (context, enrollSnap) {
                            final enrollments = enrollSnap.data ?? [];
                            final enrolledCourseIds = enrollments.map((e) => e.courseId).toSet();
                            final enrolledCourses = allCourses.where((c) => enrolledCourseIds.contains(c.id)).toList();

                            if (enrolledCourses.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        const Text('You have not enrolled in any courses yet.'),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => _tabController.animateTo(0),
                                          child: const Text('Browse All Courses'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final course = enrolledCourses[index];
                                    final enrollment = enrollments.firstWhere((e) => e.courseId == course.id);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                                      child: _EnrolledCourseCard(course: course, enrollment: enrollment),
                                    );
                                  },
                                  childCount: enrolledCourses.length,
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final course = allCourses[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                                child: _CourseCard(course: course),
                              );
                            },
                            childCount: allCourses.length,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/course/${course.id}'),
      child: Row(
        children: [
          Hero(
            tag: 'course_image_${course.id}',
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
              ),
              child: Image.network(
                course.thumbnailUrl,
                width: 110,
                height: 115,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 115,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        course.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${course.durationMinutes}m',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;

  const _EnrolledCourseCard({
    required this.course,
    required this.enrollment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      onTap: () => context.push('/course/${course.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.network(
                  course.thumbnailUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${course.category} • ${course.level}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: enrollment.progressPercent,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed ${enrollment.completedLessonIds.length} of ${course.totalLessons} lessons',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${(enrollment.progressPercent * 100).toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
