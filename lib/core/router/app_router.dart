import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/admin_dashboard_screen.dart';
import '../../presentation/screens/admin_quiz_list_screen.dart';
import '../../presentation/screens/admin_quiz_builder_screen.dart';
import '../../presentation/screens/admin_question_manager_screen.dart';
import '../../presentation/screens/admin_question_editor_screen.dart';
import '../../presentation/screens/course_details_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/lesson_player_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/progress_analytics_screen.dart';
import '../../presentation/screens/quiz_screen.dart';
import '../../presentation/screens/reminders_screen.dart';
import '../../presentation/screens/splash_onboarding_screen.dart';
import '../constants/route_names.dart';

GoRouter createRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authViewModel,
    redirect: (context, state) {
      if (!authViewModel.isInitialized) {
        return null;
      }

      final isLoggedIn = authViewModel.isAuthenticated;
      final user = authViewModel.user;
      final location = state.matchedLocation;

      final isAuthRoute = location == RouteNames.auth ||
          location == RouteNames.splash ||
          location == RouteNames.onboarding;

      if (!isLoggedIn) {
        if (!isAuthRoute) return RouteNames.auth;
        return null;
      }

      if (user == null) {
        return null;
      }

      if (user.isDisabled) {
        return RouteNames.auth;
      }

      if (isAuthRoute) {
        return user.isAdmin ? RouteNames.adminDashboard : RouteNames.home;
      }

      if (location == RouteNames.adminDashboard && !user.isAdmin) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      
      // Admin Quiz Management Routes
      GoRoute(
        path: '/admin/course/:courseId/quizzes',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return AdminQuizListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/admin/course/:courseId/quiz/form',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return AdminQuizBuilderScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/admin/course/:courseId/quiz/:quizId/edit',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return AdminQuizBuilderScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: '/admin/course/:courseId/quiz/:quizId/questions',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return AdminQuestionManagerScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: '/admin/course/:courseId/quiz/:quizId/question/new',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return AdminQuestionEditorScreen(courseId: courseId, quizId: quizId);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.progress,
                builder: (context, state) => const ProgressAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reminders,
                builder: (context, state) => const RemindersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RouteNames.courseDetails,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CourseDetailsScreen(courseId: id);
        },
      ),
      GoRoute(
        path: RouteNames.lessonPlayer,
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonPlayerScreen(courseId: courseId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/quiz/:courseId/:quizId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: RouteNames.quiz,
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return QuizScreen(courseId: courseId);
        },
      ),
    ],
  );
}

class StudentShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const StudentShellScaffold({super.key, required this.navigationShell});

  @override
  State<StudentShellScaffold> createState() => _StudentShellScaffoldState();
}

class _StudentShellScaffoldState extends State<StudentShellScaffold> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0, initialLocation: false);
        } else {
          final now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit LearnLoop'), duration: Duration(seconds: 2)),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Reminders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
