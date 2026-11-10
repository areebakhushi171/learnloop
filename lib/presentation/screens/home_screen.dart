import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/course_model.dart';
import '../../data/models/enrollment_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/common/app_text_field.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../presentation/widgets/states/empty_state.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              // Header Gradient Bar
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              name: user?.displayName ?? 'Learner',
                              radius: 24,
                              imageUrl: user?.photoUrl,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${user?.displayName ?? "Learner"} 👋',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Let's achieve today's goals",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AnimatedStreakFlame(streakDays: user?.streakDays ?? 1),
                      ],
                    ),
                  ),
                ),
              ),

              // Continue Learning Hero Section
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

                          final pct = (activeEnrollment.progressPercent * 100).toInt();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                borderRadius: AppRadius.radiusXl,
                                border: Border.all(
                                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                                ),
                                boxShadow: AppTheme.softShadow(Colors.black, isDark ? 0.2 : 0.04),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppBadge(
                                        label: 'CONTINUE LEARNING',
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        textColor: theme.colorScheme.primary,
                                        icon: Icons.play_arrow_rounded,
                                      ),
                                      Text(
                                        '$pct% Complete',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    course.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  ProgressBar(
                                    percent: activeEnrollment.progressPercent,
                                    height: 8,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 140,
                                      height: 38,
                                      child: AppButton(
                                        text: 'Resume',
                                        icon: Icons.play_arrow_rounded,
                                        onPressed: () => context.push('/course/${course.id}'),
                                      ),
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

              // Search Bar & Filter Bottom Sheet Trigger
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _searchController,
                          label: '',
                          hint: 'Search courses, categories...',
                          prefixIcon: Icons.search_rounded,
                          onChanged: homeViewModel.setSearchQuery,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: AppRadius.radiusLg,
                          border: Border.all(
                            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                          onPressed: () {
                            AppBottomSheet.show(
                              context: context,
                              title: 'Filter Courses',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeader(title: 'Categories'),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: AppConstants.categories.map((cat) {
                                      final isSelected = cat == homeViewModel.selectedCategory;
                                      return AppChip(
                                        label: cat,
                                        isSelected: isSelected,
                                        onTap: () {
                                          homeViewModel.setCategory(cat);
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Horizontal Bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = AppConstants.categories[idx];
                      final isSelected = cat == homeViewModel.selectedCategory;
                      return AppChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () => homeViewModel.setCategory(cat),
                      );
                    },
                  ),
                ),
              ),

              // Tab Bar Section Header
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'All Courses'),
                      Tab(text: 'My Enrolled Courses'),
                    ],
                  ),
                ),
              ),

              // Tab View Content Stream
              StreamBuilder<List<CourseModel>>(
                stream: homeViewModel.coursesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
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
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'No Courses Found',
                        buttonText: 'Reset Filters',
                        onButtonPressed: () {
                          homeViewModel.setCategory('All');
                          homeViewModel.setSearchQuery('');
                          _searchController.clear();
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
                                child: EmptyState(
                                  icon: Icons.school_outlined,
                                  message: 'You have not enrolled in any courses yet.',
                                  buttonText: 'Browse All Courses',
                                  onButtonPressed: () => _tabController.animateTo(0),
                                ),
                              );
                            }

                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final course = enrolledCourses[index];
                                    final enrollment = enrollments.firstWhere((e) => e.courseId == course.id);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final course = allCourses[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        child: Row(
          children: [
            Hero(
              tag: 'course_image_${course.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
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
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(
                      label: course.category,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      textColor: theme.colorScheme.primary,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer_outlined, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.radiusMd,
                    child: Image.network(
                      course.thumbnailUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${course.category} • ${course.level}', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        ProgressBar(
                          percent: enrollment.progressPercent,
                          height: 6,
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
        ),
      ),
    );
  }
}
