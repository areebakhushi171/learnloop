import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/common/app_app_bar.dart';

class PerformanceAnalyticsScreen extends StatelessWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    final courseRepo = context.watch<CourseRepository>();
    final user = authRepo.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Performance Summary'),
        body: Center(child: Text('Please log in to view performance summary.')),
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
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Scores Over Time', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spaceMd),
                SizedBox(
                  height: 220,
                  child: attempts.isEmpty
                      ? const Center(child: Text('No quiz attempts recorded yet.'))
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: attempts.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value.score);
                                }).toList(),
                                isCurved: true,
                                color: Theme.of(context).colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                Text('Strongest & Weakest Topics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spaceMd),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.trending_up_rounded, color: Colors.green),
                          title: Text('Strongest Topic'),
                          subtitle: Text('Data Structures & Algorithms (95% avg)'),
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.trending_down_rounded, color: Colors.orange),
                          title: Text('Area for Improvement'),
                          subtitle: Text('Asymptotic Complexity (60% avg)'),
                        ),
                      ],
                    ),
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
