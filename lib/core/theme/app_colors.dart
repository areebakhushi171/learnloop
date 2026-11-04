import 'package:flutter/material.dart';

enum AppAccentPalette {
  deepIndigo(
    name: 'Deep Indigo',
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF7C3AED),
    tertiary: Color(0xFF0D9488),
  ),
  emeraldTeal(
    name: 'Emerald Teal',
    primary: Color(0xFF059669),
    secondary: Color(0xFF0284C7),
    tertiary: Color(0xFFD97706),
  ),
  roseSunset(
    name: 'Rose Sunset',
    primary: Color(0xFFE11D48),
    secondary: Color(0xFF9333EA),
    tertiary: Color(0xFFEA580C),
  ),
  electricCyan(
    name: 'Electric Cyan',
    primary: Color(0xFF0284C7),
    secondary: Color(0xFF2563EB),
    tertiary: Color(0xFF10B981),
  ),
  royalAmber(
    name: 'Royal Amber',
    primary: Color(0xFFD97706),
    secondary: Color(0xFFDC2626),
    tertiary: Color(0xFF4F46E5),
  );

  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const AppAccentPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

class AppGradients {
  static LinearGradient primaryLinear(Color primary, Color secondary) {
    return LinearGradient(
      colors: [primary, secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient glassLight(Color baseColor) {
    return LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.85),
        baseColor.withValues(alpha: 0.50),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient streakFlame = const LinearGradient(
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B), Color(0xFFFFB199)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static LinearGradient xpShine = const LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSemanticColors {
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color xpGold = Color(0xFFF59E0B);
  static const Color streakOrange = Color(0xFFF97316);
}
