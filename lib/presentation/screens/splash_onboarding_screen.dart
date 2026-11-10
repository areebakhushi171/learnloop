import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/splash_onboarding_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    final stopwatch = Stopwatch()..start();

    final splashVM = context.read<SplashOnboardingViewModel>();
    final authVM = context.read<AuthViewModel>();

    while (!authVM.isInitialized && stopwatch.elapsedMilliseconds < 3000) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (!mounted) return;

    if (!splashVM.hasSeenOnboarding) {
      context.go('/onboarding');
      return;
    }

    if (authVM.isAuthenticated && authVM.user != null) {
      if (authVM.user!.isAdmin) {
        context.go('/admin-dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppGradients.heroHeader(
            theme.colorScheme.primary,
            AppColors.accentLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1200.ms),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppConstants.appName,
              style: theme.textTheme.displayLarge?.copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppConstants.appTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.2,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'Learn with Focus & Clarity',
      'description': 'Structured, modular curricula designed by industry authorities for sustained mastery.',
      'icon': 'school_rounded',
    },
    {
      'title': 'Retain with Micro-Quizzes',
      'description': 'Reinforce memory retention with timed dynamic assessments and rapid analytics feedback.',
      'icon': 'psychology_rounded',
    },
    {
      'title': 'Build Daily Study Habits',
      'description': 'Keep your daily streak alive, rise on the global student leaderboard, and unlock verified milestones.',
      'icon': 'local_fire_department_rounded',
    },
  ];

  Future<void> _finishOnboarding() async {
    await context.read<SplashOnboardingViewModel>().completeOnboarding();
    if (!mounted) return;
    context.go('/auth');
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'school_rounded':
        return Icons.school_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'local_fire_department_rounded':
      default:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SplashOnboardingViewModel>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: viewModel.setPage,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(page['icon']!),
                            size: 68,
                            color: theme.colorScheme.primary,
                          ),
                        )
                            .animate(target: viewModel.currentPage == index ? 1 : 0)
                            .scale(duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page['description']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: viewModel.currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: viewModel.currentPage == i
                              ? theme.colorScheme.primary
                              : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                          borderRadius: AppRadius.radiusFull,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: AppButton(
                      text: viewModel.currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      onPressed: () {
                        if (viewModel.currentPage < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
