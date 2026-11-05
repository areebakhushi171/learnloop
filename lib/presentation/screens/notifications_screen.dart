import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common/app_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Notifications Center'),
      body: ListView(
        key: const PageStorageKey('notifications_scroll_key'),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.notifications_rounded)),
            title: Text('Welcome to LearnLoop'),
            subtitle: Text('Explore courses and start your learning journey today!'),
            trailing: Text('Just now', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
