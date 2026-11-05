import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String title;
  final String time; // e.g. "08:00"
  final List<int> days; // 1 to 7
  final bool isEnabled;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.time,
    required this.days,
    required this.isEnabled,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return ReminderModel(
      id: snapshot.id,
      title: data['title'] ?? 'Study Reminder',
      time: data['time'] ?? '08:00',
      days: List<int>.from(data['days'] ?? []),
      isEnabled: data['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'time': time,
      'days': days,
      'isEnabled': isEnabled,
    };
  }
}
