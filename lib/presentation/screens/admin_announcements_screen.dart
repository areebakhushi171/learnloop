import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Manage Announcements'),
      body: SingleChildScrollView(
        key: const PageStorageKey('admin_announcements_scroll_key'),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            AppTextField(controller: _titleController, label: 'Announcement Title'),
            const SizedBox(height: AppTheme.spaceMd),
            AppTextField(controller: _messageController, label: 'Message Body'),
            const SizedBox(height: AppTheme.spaceXl),
            AppButton(
              text: 'Post Announcement',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement posted successfully!'), backgroundColor: Colors.green),
                );
                _titleController.clear();
                _messageController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}
