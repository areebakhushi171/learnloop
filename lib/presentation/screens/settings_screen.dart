import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings & Preferences', showBack: false),
      body: ListView(
        key: const PageStorageKey('settings_scroll_key'),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: [
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeVM.themeMode == ThemeMode.dark,
            onChanged: (val) {
              themeVM.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 32),
          const Text('About LearnLoop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0+1'),
          ),
          const ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
