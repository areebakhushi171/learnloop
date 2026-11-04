import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/services/firestore_seeder.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/reminders_viewmodel.dart';
import 'viewmodels/progress_viewmodel.dart';
import 'viewmodels/splash_onboarding_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce preferred portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive system overlay UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase with platform credentials
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Local Cache
  final sharedPreferences = await SharedPreferences.getInstance();

  // Seed sample courses in Firestore if empty
  try {
    final seeder = FirestoreSeeder();
    await seeder.seedInitialCoursesIfEmpty();
  } catch (_) {
    // Non-blocking if offline or initial setup
  }

  // Instantiate Repositories
  final authRepository = FirebaseAuthRepository();
  final courseRepository = FirestoreCourseRepository();

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        Provider<AuthRepository>.value(value: authRepository),
        Provider<CourseRepository>.value(value: courseRepository),

        // App-wide ViewModels
        ChangeNotifierProvider(create: (_) => ThemeViewModel(sharedPreferences)),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => HomeViewModel(courseRepository)),
        ChangeNotifierProvider(create: (_) => RemindersViewModel()),
        ChangeNotifierProvider(create: (_) => ProgressViewModel()),
        ChangeNotifierProvider(create: (_) => SplashOnboardingViewModel(sharedPreferences)),
        ChangeNotifierProvider(create: (_) => ProfileViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => AdminViewModel(courseRepository)),
      ],
      child: const LearnLoopApp(),
    ),
  );
}

class LearnLoopApp extends StatefulWidget {
  const LearnLoopApp({super.key});

  @override
  State<LearnLoopApp> createState() => _LearnLoopAppState();
}

class _LearnLoopAppState extends State<LearnLoopApp> {
  late final router = createRouter(context.read<AuthViewModel>());

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    return MaterialApp.router(
      title: 'LearnLoop',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeVM.themeMode,
      theme: AppTheme.light(themeVM.accentPalette),
      darkTheme: AppTheme.dark(themeVM.accentPalette),
    );
  }
}
