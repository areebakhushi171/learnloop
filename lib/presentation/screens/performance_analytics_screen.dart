import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/section_header.dart';
import '../widgets/states/empty_state.dart';

class PerformanceAnalyticsScreen extends StatelessWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authRepo = context.watch<AuthRepository>();
    final courseRepo = context.watch<CourseRepository>();
    final user = authRepo.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Performance Summary'),
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Please log in to view performance summary.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Performance Summary',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              Share.share('Check out my learning progress and quiz performance on LearnLoop!');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<QuizAttemptModel>>(
        stream: courseRepo.streamAllUserQuizAttempts(user.uid),
        builder: (context, snapshot) {
          final attempts = snapshot.data ?? [];

          return SingleChildScrollView(
            key: const PageStorageKey('performance_scroll_key'),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Quiz Scores Over Time'),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 220,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ),
                  child: attempts.isEmpty
                      ? const Center(child: Text('No quiz attempts recorded yet.'))
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: true),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: attempts.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value.score);
                                }).toList(),
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Strongest & Weakest Topics'),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.trending_up_rounded, color: AppColors.success),
                        title: Text('Strongest Topic', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Data Structures & Algorithms (95% avg)'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.trending_down_rounded, color: AppColors.warning),
                        title: Text('Area for Improvement', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Asymptotic Complexity (60% avg)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
