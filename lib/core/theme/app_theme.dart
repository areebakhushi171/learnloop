import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  const AppTheme._();

  // Compatibility Spacing & Radii
  static const double space2xs = 2.0;
  static const double spaceXs = AppSpacing.xs;
  static const double spaceSm = AppSpacing.sm;
  static const double spaceMd = AppSpacing.md;
  static const double spaceLg = AppSpacing.lg;
  static const double spaceXl = AppSpacing.xl;
  static const double space2xl = AppSpacing.xxl;

  static const double radiusSmall = AppRadius.sm;
  static const double radiusMedium = AppRadius.md;
  static const double radiusLarge = AppRadius.lg;

  static List<BoxShadow> softShadow([Color? color, double? opacity]) {
    final alpha = opacity ?? 0.05;
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: alpha),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static ThemeData light(dynamic palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData dark(dynamic palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
