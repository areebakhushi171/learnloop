import 'package:flutter/material.dart';

class ReminderItem {
  final String id;
  final String title;
  final String time;
  final bool enabled;

  const ReminderItem({
    required this.id,
    required this.title,
    required this.time,
    required this.enabled,
  });

  ReminderItem copyWith({
    String? id,
    String? title,
    String? time,
    bool? enabled,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
    );
  }
}

class RemindersViewModel extends ChangeNotifier {
  List<ReminderItem> _reminders = [
    const ReminderItem(
      id: '1',
      title: 'Morning Concept Drill',
      time: '08:00 AM',
      enabled: true,
    ),
    const ReminderItem(
      id: '2',
      title: 'Afternoon Coding Challenge',
      time: '02:30 PM',
      enabled: true,
    ),
    const ReminderItem(
      id: '3',
      title: 'Nightly Streak Shield Review',
      time: '09:00 PM',
      enabled: false,
    ),
  ];

  List<ReminderItem> get reminders => _reminders;

  void toggleReminder(String id) {
    _reminders = _reminders.map((r) {
      if (r.id == id) {
        return r.copyWith(enabled: !r.enabled);
      }
      return r;
    }).toList();
    notifyListeners();
  }

  void addReminder(String title, TimeOfDay timeOfDay, BuildContext context) {
    final formatted = timeOfDay.format(context);
    final newItem = ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? 'Custom Study Target' : title,
      time: formatted,
      enabled: true,
    );
    _reminders = [..._reminders, newItem];
    notifyListeners();
  }
}
