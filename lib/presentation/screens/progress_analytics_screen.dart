import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';
import '../widgets/custom_widgets.dart';

class ProgressAnalyticsScreen extends StatelessWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthViewModel>().user;
    final progressVM = context.watch<ProgressViewModel>();

    // Keep progress synchronized with user totalXp
    if (user != null && progressVM.totalXp != user.totalXp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        progressVM.updateWithUser(user);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rank: Level ${progressVM.currentLevel} Master', style: theme.textTheme.titleMedium),
                      Text('${progressVM.totalXp} / ${progressVM.nextLevelXp} XP', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  LinearProgressIndicator(
                    value: progressVM.levelProgress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppSemanticColors.xpGold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            Text('Weekly Study Time (Hours)', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              height: 200,
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
            const SizedBox(height: AppTheme.space2xl),
            Text('Topic Strength Breakdown', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spaceMd),
            ...progressVM.topicProficiencies.map(
              (topic) => _TopicStatTile(
                title: topic.title,
                percent: topic.percent,
                tier: topic.tier,
                color: topic.percent > 0.8
                    ? Colors.green
                    : topic.percent > 0.6
                        ? Colors.blue
                        : Colors.orange,
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
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$tier (${(percent * 100).toInt()}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
