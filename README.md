# LearnLoop

LearnLoop is a portfolio-grade student learning progress, courses, quizzes, and performance tracking application built with Flutter 3.x, Dart 3, Material 3, and Firebase.

## Setup & Firebase Configuration

1. **Firebase Console**:
   - Create a Firebase project with Authentication (Email/Password), Firestore Database, and Firebase Storage.
   - Register your Android and iOS apps and place `google-services.json` (`android/app/`) and `GoogleService-Info.plist` (iOS) in their respective directories.
2. **First Admin Setup**:
   - Sign up a new user through the app.
   - Go to the Firebase Console -> Firestore Database -> `users` collection -> locate your user document and manually update the `role` field from `"student"` to `"admin"`.
3. **Security Rules & Indexes**:
   - Deploy Firestore security rules (`firestore.rules`) and indexes (`firestore.indexes.json`).
   - Deploy Storage rules (`storage.rules`).
4. **Permissions**:
   - Android 13+ notification permissions and exact alarm permissions are declared in `AndroidManifest.xml`.

## Running Tests
Run unit and widget tests using:
```bash
flutter test
```
