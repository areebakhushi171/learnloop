import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class ThemeViewModel extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  AppAccentPalette _accentPalette;

  ThemeViewModel(this._prefs)
      : _themeMode = _loadThemeMode(_prefs),
        _accentPalette = _loadAccentPalette(_prefs);

  ThemeMode get themeMode => _themeMode;
  AppAccentPalette get accentPalette => _accentPalette;

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final mode = prefs.getString('user_theme_mode') ?? 'system';
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static AppAccentPalette _loadAccentPalette(SharedPreferences prefs) {
    final name = prefs.getString('user_accent_palette') ?? 'deepIndigo';
    return AppAccentPalette.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppAccentPalette.deepIndigo,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString('user_theme_mode', modeStr);
    notifyListeners();
  }

  Future<void> setAccentPalette(AppAccentPalette palette) async {
    if (_accentPalette == palette) return;
    _accentPalette = palette;
    await _prefs.setString('user_accent_palette', palette.name);
    notifyListeners();
  }
}
