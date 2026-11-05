import 'package:cloud_firestore/cloud_firestore.dart';

class StudyLogModel {
  final String dateKey; // yyyy-MM-dd
  final int seconds;
  final int lessonsCompleted;

  const StudyLogModel({
    required this.dateKey,
    required this.seconds,
    required this.lessonsCompleted,
  });

  factory StudyLogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return StudyLogModel(
      dateKey: snapshot.id,
      seconds: (data['seconds'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (data['lessonsCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seconds': seconds,
      'lessonsCompleted': lessonsCompleted,
    };
  }
}
