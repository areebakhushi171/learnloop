import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashOnboardingViewModel extends ChangeNotifier {
  final SharedPreferences _prefs;
  int _currentPage = 0;

  SplashOnboardingViewModel(this._prefs);

  bool get hasSeenOnboarding => _prefs.getBool('seen_onboarding') ?? false;
  int get currentPage => _currentPage;

  void setPage(int page) {
    if (_currentPage == page) return;
    _currentPage = page;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('seen_onboarding', true);
    notifyListeners();
  }
}
