import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1 = Mon, 7 = Sun
  final bool isEnabled;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return ReminderModel(
      id: snapshot.id,
      title: data['title'] ?? 'Study Session',
      hour: (data['hour'] as num?)?.toInt() ?? 18,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? [1, 2, 3, 4, 5]),
      isEnabled: data['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }
}
