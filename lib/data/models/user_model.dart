import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'student' or 'admin'
  final int totalXp;
  final int streakDays;
  final DateTime? lastActiveDate;
  final int dailyGoalMinutes;
  final String preferredTheme; // 'system', 'light', 'dark'
  final String accentPalette;
  final String languageCode; // 'en' or 'ur'
  final List<String> bookmarkedCourseIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'student',
    this.totalXp = 0,
    this.streakDays = 0,
    this.lastActiveDate,
    this.dailyGoalMinutes = 30,
    this.preferredTheme = 'system',
    this.accentPalette = 'deepIndigo',
    this.languageCode = 'en',
    this.bookmarkedCourseIds = const [],
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return UserModel(
      uid: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Student',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'student',
      totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate(),
      dailyGoalMinutes: (data['dailyGoalMinutes'] as num?)?.toInt() ?? 30,
      preferredTheme: data['preferredTheme'] ?? 'system',
      accentPalette: data['accentPalette'] ?? 'deepIndigo',
      languageCode: data['languageCode'] ?? 'en',
      bookmarkedCourseIds: List<String>.from(data['bookmarkedCourseIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'totalXp': totalXp,
      'streakDays': streakDays,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'dailyGoalMinutes': dailyGoalMinutes,
      'preferredTheme': preferredTheme,
      'accentPalette': accentPalette,
      'languageCode': languageCode,
      'bookmarkedCourseIds': bookmarkedCourseIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? role,
    int? totalXp,
    int? streakDays,
    DateTime? lastActiveDate,
    int? dailyGoalMinutes,
    String? preferredTheme,
    String? accentPalette,
    String? languageCode,
    List<String>? bookmarkedCourseIds,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      accentPalette: accentPalette ?? this.accentPalette,
      languageCode: languageCode ?? this.languageCode,
      bookmarkedCourseIds: bookmarkedCourseIds ?? this.bookmarkedCourseIds,
      createdAt: createdAt,
    );
  }
}
