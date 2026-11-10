import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../viewmodels/theme_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeVM = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings & Preferences', showBack: false),
      body: ListView(
        key: const PageStorageKey('settings_scroll_key'),
        padding: AppSpacing.screenPadding,
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Enable dark theme across the entire application'),
              value: themeVM.themeMode == ThemeMode.dark,
              onChanged: (val) {
                themeVM.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'About LearnLoop'),
          const SizedBox(height: AppSpacing.xs),
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
                  title: Text('Application Version', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text('1.0.0+1', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
