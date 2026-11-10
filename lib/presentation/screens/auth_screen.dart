import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart' as theme_colors;
import '../../core/utils/screen_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../presentation/widgets/common/app_button.dart';
import '../../presentation/widgets/common/app_text_field.dart';
import '../../viewmodels/auth_viewmodel.dart';

enum AuthMode { login, signup, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  final _forgotEmailController = TextEditingController();

  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();

  final _signupNameFocus = FocusNode();
  final _signupEmailFocus = FocusNode();
  final _signupPasswordFocus = FocusNode();
  final _signupConfirmPasswordFocus = FocusNode();

  final _forgotEmailFocus = FocusNode();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _forgotEmailController.dispose();

    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _signupNameFocus.dispose();
    _signupEmailFocus.dispose();
    _signupPasswordFocus.dispose();
    _signupConfirmPasswordFocus.dispose();
    _forgotEmailFocus.dispose();

    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _obscureLoginPassword = true;
      _obscureSignupPassword = true;
      _obscureConfirmPassword = true;
    });
  }

  String? _validateName(String? val) {
    final trimmed = val?.trim() ?? '';
    if (trimmed.isEmpty) return 'Full Name is required.';
    if (trimmed.length < 3) return 'Name must be at least 3 characters.';
    return null;
  }

  String? _validateEmail(String? val) {
    final trimmed = val?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email address is required.';
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) return 'Please enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required.';
    if (val.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password.';
    if (val != _signupPasswordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.signInWithEmailPassword(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) return;
    if (success) {
      final user = viewModel.user;
      if (user != null) {
        context.go(user.isAdmin ? '/admin-dashboard' : '/home');
      }
    } else {
      final error = viewModel.errorMessage ?? 'Sign in failed. Check credentials.';
      SnackbarUtils.showError(context, error);
    }
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    if (!(_signupFormKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.signUpWithEmailPassword(
      _signupEmailController.text.trim(),
      _signupPasswordController.text,
      _signupNameController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, viewModel.successMessage ?? 'Account created successfully!');
      final user = viewModel.user;
      if (user != null) {
        context.go(user.isAdmin ? '/admin-dashboard' : '/home');
      }
    } else {
      final error = viewModel.errorMessage ?? 'Signup failed. Please try again.';
      SnackbarUtils.showError(context, error);
    }
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_forgotFormKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.sendPasswordResetEmail(_forgotEmailController.text.trim());

    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, viewModel.successMessage ?? 'Password reset link sent to your inbox.');
      _switchMode(AuthMode.login);
    } else {
      final error = viewModel.errorMessage ?? 'Failed to send reset email.';
      SnackbarUtils.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authViewModel = context.watch<AuthViewModel>();
    final isTablet = ScreenUtils.isTablet(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48.0 : AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: AppRadius.radiusXxl,
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Branding with Glow
                      Center(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: theme_colors.AppGradients.primaryLinear(
                                theme.colorScheme.primary,
                                AppColors.accentLight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Heading Title & Subtitle
                        Text(
                          _getHeaderTitle(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _getHeaderSubtitle(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Form Body
                      if (_mode == AuthMode.login)
                        Form(
                          key: _loginFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: _buildLoginForm(theme),
                        ),
                      if (_mode == AuthMode.signup)
                        Form(
                          key: _signupFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: _buildSignupForm(theme),
                        ),
                      if (_mode == AuthMode.forgotPassword)
                        Form(
                          key: _forgotFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: _buildForgotPasswordForm(theme),
                        ),

                      const SizedBox(height: AppSpacing.xl),

                      // Primary Button
                      AppButton(
                        text: _getSubmitButtonText(),
                        isLoading: authViewModel.isLoading,
                        onPressed: () {
                          if (_mode == AuthMode.login) _handleLogin();
                          if (_mode == AuthMode.signup) _handleSignup();
                          if (_mode == AuthMode.forgotPassword) _handleForgotPassword();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Footer Navigation Links
                      _buildFooterNavigation(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_mode) {
      case AuthMode.login:
        return 'Welcome Back';
      case AuthMode.signup:
        return 'Create Account';
      case AuthMode.forgotPassword:
        return 'Reset Password';
    }
  }

  String _getHeaderSubtitle() {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign in to continue your learning progress';
      case AuthMode.signup:
        return 'Join LearnLoop and accelerate your skills';
      case AuthMode.forgotPassword:
        return 'Enter your email to receive recovery instructions';
    }
  }

  String _getSubmitButtonText() {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign In';
      case AuthMode.signup:
        return 'Sign Up';
      case AuthMode.forgotPassword:
        return 'Send Reset Link';
    }
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      children: [
        AppTextField(
          controller: _loginEmailController,
          focusNode: _loginEmailFocus,
          label: 'Email Address',
          hint: 'name@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_loginPasswordFocus),
          validator: _validateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _loginPasswordController,
          focusNode: _loginPasswordFocus,
          label: 'Password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureLoginPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          suffixIcon: IconButton(
            icon: Icon(_obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _switchMode(AuthMode.forgotPassword),
            child: const Text('Forgot Password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(ThemeData theme) {
    return Column(
      children: [
        AppTextField(
          controller: _signupNameController,
          focusNode: _signupNameFocus,
          label: 'Full Name',
          hint: 'John Doe',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_signupEmailFocus),
          validator: _validateName,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _signupEmailController,
          focusNode: _signupEmailFocus,
          label: 'Email Address',
          hint: 'name@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_signupPasswordFocus),
          validator: _validateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _signupPasswordController,
          focusNode: _signupPasswordFocus,
          label: 'Password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureSignupPassword,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_signupConfirmPasswordFocus),
          suffixIcon: IconButton(
            icon: Icon(_obscureSignupPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _signupConfirmPasswordController,
          focusNode: _signupConfirmPasswordFocus,
          label: 'Confirm Password',
          prefixIcon: Icons.lock_reset_rounded,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSignup(),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: _validateConfirmPassword,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme) {
    return Column(
      children: [
        AppTextField(
          controller: _forgotEmailController,
          focusNode: _forgotEmailFocus,
          label: 'Email Address',
          hint: 'Enter your registered email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleForgotPassword(),
          validator: _validateEmail,
        ),
      ],
    );
  }

  Widget _buildFooterNavigation(ThemeData theme) {
    if (_mode == AuthMode.login) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account?"),
          TextButton(
            onPressed: () => _switchMode(AuthMode.signup),
            child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (_mode == AuthMode.signup) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Already have an account?'),
          TextButton(
            onPressed: () => _switchMode(AuthMode.login),
            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Remembered your password?'),
          TextButton(
            onPressed: () => _switchMode(AuthMode.login),
            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}
