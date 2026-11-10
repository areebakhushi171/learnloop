import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/common/app_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppAppBar(title: 'Notifications Center'),
      body: ListView(
        key: const PageStorageKey('notifications_scroll_key'),
        padding: AppSpacing.screenPadding,
        children: [
          Material(
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
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.notifications_rounded, color: theme.colorScheme.primary),
              ),
              title: const Text('Welcome to LearnLoop', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Explore courses and start your learning journey today!'),
              trailing: Text(
                'Just now',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
