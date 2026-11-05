class RouteNames {
  const RouteNames._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String adminDashboard = '/admin-dashboard';
  static const String courseDetails = '/course/:id';
  static const String lessonPlayer = '/course/:courseId/lesson/:lessonId';
  static const String quiz = '/quiz/:courseId';
  static const String progress = '/progress';
  static const String reminders = '/reminders';
  static const String profile = '/profile';
}
