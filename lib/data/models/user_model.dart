import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // "student" | "admin"
  final int xp;
  final int level;
  final int streak;
  final DateTime? lastStudyDate;
  final int totalStudySeconds;
  final int dailyGoalMinutes;
  final String preferredTheme; // "system" | "light" | "dark"
  final String accentPalette;
  final String languageCode; // "en" | "ur"
  final List<String> bookmarkedCourseIds;
  final DateTime createdAt;
  final bool isDisabled;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.xp,
    required this.level,
    required this.streak,
    this.lastStudyDate,
    required this.totalStudySeconds,
    this.dailyGoalMinutes = 30,
    this.preferredTheme = 'system',
    this.accentPalette = 'deepIndigo',
    this.languageCode = 'en',
    this.bookmarkedCourseIds = const [],
    required this.createdAt,
    this.isDisabled = false,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  // Compatibility getters
  String get displayName => name;
  int get totalXp => xp;
  int get streakDays => streak;
  DateTime? get lastActiveDate => lastStudyDate;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return UserModel(
      uid: snapshot.id,
      name: data['name'] ?? data['displayName'] ?? 'Student',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'student',
      xp: (data['xp'] as num?)?.toInt() ?? (data['totalXp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      streak: (data['streak'] as num?)?.toInt() ?? (data['streakDays'] as num?)?.toInt() ?? 0,
      lastStudyDate: (data['lastStudyDate'] as Timestamp?)?.toDate() ?? (data['lastActiveDate'] as Timestamp?)?.toDate(),
      totalStudySeconds: (data['totalStudySeconds'] as num?)?.toInt() ?? 0,
      dailyGoalMinutes: (data['dailyGoalMinutes'] as num?)?.toInt() ?? 30,
      preferredTheme: data['preferredTheme'] ?? 'system',
      accentPalette: data['accentPalette'] ?? 'deepIndigo',
      languageCode: data['languageCode'] ?? 'en',
      bookmarkedCourseIds: List<String>.from(data['bookmarkedCourseIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDisabled: data['isDisabled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'xp': xp,
      'level': level,
      'streak': streak,
      'lastStudyDate': lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'totalStudySeconds': totalStudySeconds,
      'dailyGoalMinutes': dailyGoalMinutes,
      'preferredTheme': preferredTheme,
      'accentPalette': accentPalette,
      'languageCode': languageCode,
      'bookmarkedCourseIds': bookmarkedCourseIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDisabled': isDisabled,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? role,
    int? xp,
    int? level,
    int? streak,
    DateTime? lastStudyDate,
    int? totalStudySeconds,
    int? dailyGoalMinutes,
    String? preferredTheme,
    String? accentPalette,
    String? languageCode,
    List<String>? bookmarkedCourseIds,
    bool? isDisabled,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      accentPalette: accentPalette ?? this.accentPalette,
      languageCode: languageCode ?? this.languageCode,
      bookmarkedCourseIds: bookmarkedCourseIds ?? this.bookmarkedCourseIds,
      createdAt: createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
