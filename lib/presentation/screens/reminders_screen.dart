import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/reminders_viewmodel.dart';
import '../widgets/custom_widgets.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _showAddReminderDialog(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null && context.mounted) {
      context.read<RemindersViewModel>().addReminder(
            'Daily Study Target',
            picked,
            context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<RemindersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Reminders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Add Time'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        itemCount: viewModel.reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMd),
        itemBuilder: (context, index) {
          final rem = viewModel.reminders[index];
          return GlassContainer(
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
                    const SizedBox(width: AppTheme.spaceMd),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rem.title, style: theme.textTheme.titleMedium),
                        Text(rem.time, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: rem.enabled,
                  onChanged: (_) => viewModel.toggleReminder(rem.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
