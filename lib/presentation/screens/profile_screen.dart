import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dialog_utils.dart';
import '../../presentation/widgets/common/app_app_bar.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/common/section_header.dart';
import '../../presentation/widgets/custom_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthViewModel>().user;
    final themeVM = context.watch<ThemeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Learner Profile'),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  AppAvatar(
                    name: user?.displayName ?? 'Learner',
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
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.displayName ?? 'Learner',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(
                  label: (user?.role ?? 'student').toUpperCase(),
                  backgroundColor: theme.colorScheme.primary,
                  textColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(user?.email ?? '', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xl),

            // Theme Accent Palette Selection
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

            // Appearance Mode Dropdown
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
                  message: 'Are you sure you want to sign out of LearnLoop?',
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
