import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_utils.dart';
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
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            AppTextField(controller: _titleController, label: 'Announcement Title'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _messageController,
              label: 'Message Body',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Post Announcement',
              icon: Icons.campaign_rounded,
              onPressed: () {
                SnackbarUtils.showSuccess(context, 'Announcement posted successfully!');
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
