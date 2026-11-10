import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBack;
  final bool isTransparent;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBack = true,
    this.isTransparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final shouldShowBack = showBack && (canPop || ModalRoute.of(context)?.impliesAppBarDismissal == true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget appBarChild = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      leading: shouldShowBack
          ? Semantics(
              label: 'Back',
              button: true,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
                tooltip: 'Back',
                onPressed: onBackPressed ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
              ),
            )
          : null,
      actions: actions,
    );

    if (isTransparent) {
      return appBarChild;
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.82),
          child: appBarChild,
        ),
      ),
    );
  }
}
