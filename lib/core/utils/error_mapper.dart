import 'package:firebase_auth/firebase_auth.dart';

class ErrorMapper {
  const ErrorMapper._();

  static String map(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'user-not-found':
          return 'No registered account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please verify and try again.';
        case 'invalid-credential':
          return 'Invalid login credentials provided.';
        case 'email-already-in-use':
          return 'An account with this email address already exists.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        case 'network-request-failed':
          return 'Network failure. Check your connection.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
