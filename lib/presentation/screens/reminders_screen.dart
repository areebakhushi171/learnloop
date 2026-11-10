import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/reminder_model.dart';
import '../../viewmodels/reminders_viewmodel.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/states/empty_state.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _showAddReminderDialog(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null && context.mounted) {
      await context.read<RemindersViewModel>().addReminder(
            'Daily Study Target',
            picked,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<RemindersViewModel>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Study Reminders'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Add Time', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: viewModel.remindersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.alarm_off_rounded,
                message: 'No study reminders set yet. Tap "Add Time" to schedule one.',
                buttonText: 'Add Reminder',
                onButtonPressed: () => _showAddReminderDialog(context),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final rem = reminders[index];
              return Container(
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
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rem.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(rem.time, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Switch(
                          value: rem.isEnabled,
                          onChanged: (_) => viewModel.toggleReminder(rem),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => viewModel.deleteReminder(rem.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
