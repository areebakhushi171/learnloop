import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/admin_dashboard_screen.dart';
import '../../presentation/screens/course_details_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/lesson_player_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/progress_analytics_screen.dart';
import '../../presentation/screens/quiz_screen.dart';
import '../../presentation/screens/reminders_screen.dart';
import '../../presentation/screens/splash_onboarding_screen.dart';

GoRouter createRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authViewModel,
    redirect: (context, state) {
      if (!authViewModel.isInitialized) {
        return null;
      }

      final isLoggedIn = authViewModel.isAuthenticated;
      final user = authViewModel.user;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/auth' ||
          location == '/splash' ||
          location == '/onboarding';

      // 1. Unauthenticated users must be redirected to /auth
      if (!isLoggedIn) {
        if (!isAuthRoute) return '/auth';
        return null;
      }

      // 2. Wait until user profile document is loaded
      if (user == null) {
        return null;
      }

      // 3. Authenticated user opening auth/splash/onboarding -> redirect to respective role dashboard
      if (isAuthRoute) {
        return user.isAdmin ? '/admin-dashboard' : '/home';
      }

      // 4. Role-based Route Protection
      if (location == '/admin-dashboard' && !user.isAdmin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CourseDetailsScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/course/:courseId/lesson/:lessonId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonPlayerScreen(courseId: courseId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/quiz/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return QuizScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressAnalyticsScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
