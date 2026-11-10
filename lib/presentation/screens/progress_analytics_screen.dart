import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';

class ProgressAnalyticsScreen extends StatelessWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthViewModel>().user;
    final progressVM = context.watch<ProgressViewModel>();

    if (user != null && progressVM.totalXp != user.totalXp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        progressVM.updateWithUser(user);
      });
    }

    return Scaffold(
      appBar: const AppAppBar(title: 'Performance & Analytics'),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(
                        'Rank: Level ${progressVM.currentLevel} Master',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${progressVM.totalXp} / ${progressVM.nextLevelXp} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressBar(
                    percent: progressVM.levelProgress,
                    height: 10,
                    color: AppColors.xpGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Weekly Study Time (Hours)'),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 200,
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                ),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 6,
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
                  barGroups: List.generate(
                    progressVM.weeklyHours.length,
                    (idx) => BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: progressVM.weeklyHours[idx],
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Topic Strength Breakdown'),
            const SizedBox(height: AppSpacing.md),
            ...progressVM.topicProficiencies.map(
              (topic) => _TopicStatTile(
                title: topic.title,
                percent: topic.percent,
                tier: topic.tier,
                color: topic.percent > 0.8
                    ? AppColors.success
                    : topic.percent > 0.6
                        ? AppColors.info
                        : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicStatTile extends StatelessWidget {
  final String title;
  final double percent;
  final String tier;
  final Color color;

  const _TopicStatTile({
    required this.title,
    required this.percent,
    required this.tier,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$tier (${(percent * 100).toInt()}%)', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(
            percent: percent,
            height: 6,
            color: color,
          ),
        ],
      ),
    );
  }
}
