import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String type;
  final DateTime unlockedAt;

  const AchievementModel({
    required this.id,
    required this.type,
    required this.unlockedAt,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return AchievementModel(
      id: snapshot.id,
      type: data['type'] ?? '',
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }
}
