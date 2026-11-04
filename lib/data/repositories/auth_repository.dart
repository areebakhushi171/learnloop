import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserModel?> getUserProfile(String uid);
  Stream<UserModel?> streamUserProfile(String uid);
  Future<UserModel> signInWithEmailPassword(String email, String password);
  Future<UserModel> signUpWithEmailPassword(String email, String password, String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> updateProfile({String? displayName, String? photoUrl});
  Future<String> uploadProfileImage(String uid, File file);
  Future<void> updateUserSettings(String uid, {
    String? theme,
    String? accent,
    String? language,
    int? dailyGoalMinutes,
  });
  Future<void> updateStreakAndXp(String uid, {int xpToAdd = 0});
  Future<void> signOut();
  Future<void> deleteAccount();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  @override
  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    final profile = await getUserProfile(user.uid);
    if (profile != null) {
      await updateStreakAndXp(user.uid, xpToAdd: 10);
      return profile;
    }

    // Self-healing: if an existing Firebase Auth account has no Firestore doc, initialize as student
    final now = DateTime.now();
    final displayName = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : email.trim().split('@').first;

    final newModel = UserModel(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: displayName,
      role: 'student',
      totalXp: 0,
      streakDays: 1,
      dailyGoalMinutes: 30,
      preferredTheme: 'system',
      accentPalette: 'deepIndigo',
      languageCode: 'en',
      bookmarkedCourseIds: const [],
      createdAt: now,
      lastActiveDate: now,
    );

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email ?? email.trim(),
      'displayName': displayName,
      'photoUrl': user.photoURL,
      'role': 'student',
      'totalXp': 0,
      'streakDays': 1,
      'lastActiveDate': FieldValue.serverTimestamp(),
      'dailyGoalMinutes': 30,
      'preferredTheme': 'system',
      'accentPalette': 'deepIndigo',
      'languageCode': 'en',
      'bookmarkedCourseIds': const [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newModel;
  }

  @override
  Future<UserModel> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName.trim());

    final now = DateTime.now();
    final newModel = UserModel(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      role: 'student', // Strictly assigned student role
      totalXp: 0,
      streakDays: 0,
      dailyGoalMinutes: 30,
      preferredTheme: 'system',
      accentPalette: 'deepIndigo',
      languageCode: 'en',
      bookmarkedCourseIds: const [],
      createdAt: now,
      lastActiveDate: now,
    );

    await _firestore.collection('users').doc(user.uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'photoUrl': null,
      'role': 'student',
      'totalXp': 0,
      'streakDays': 0,
      'lastActiveDate': FieldValue.serverTimestamp(),
      'dailyGoalMinutes': 30,
      'preferredTheme': 'system',
      'accentPalette': 'deepIndigo',
      'languageCode': 'en',
      'bookmarkedCourseIds': const [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newModel;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    final Map<String, dynamic> updates = {};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  @override
  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _storage.ref().child('user_avatars').child('$uid.jpg');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await updateProfile(photoUrl: downloadUrl);
    return downloadUrl;
  }

  @override
  Future<void> updateUserSettings(
    String uid, {
    String? theme,
    String? accent,
    String? language,
    int? dailyGoalMinutes,
  }) async {
    final Map<String, dynamic> updates = {};
    if (theme != null) updates['preferredTheme'] = theme;
    if (accent != null) updates['accentPalette'] = accent;
    if (language != null) updates['languageCode'] = language;
    if (dailyGoalMinutes != null) updates['dailyGoalMinutes'] = dailyGoalMinutes;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  @override
  Future<void> updateStreakAndXp(String uid, {int xpToAdd = 0}) async {
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final int currentXp = (data['totalXp'] as num?)?.toInt() ?? 0;
      final int currentStreak = (data['streakDays'] as num?)?.toInt() ?? 0;
      final Timestamp? lastActiveTs = data['lastActiveDate'] as Timestamp?;

      int newStreak = currentStreak;
      final now = DateTime.now();

      if (lastActiveTs == null) {
        newStreak = 1;
      } else {
        final lastDate = lastActiveTs.toDate();
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (diffDays == 1) {
          newStreak += 1;
        } else if (diffDays > 1) {
          newStreak = 1;
        }
      }

      transaction.update(docRef, {
        'totalXp': currentXp + xpToAdd,
        'streakDays': newStreak,
        'lastActiveDate': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
  }
}
