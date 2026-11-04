import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

enum AuthMode { login, signup, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;

  // Separate form keys for each mode
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  // Password visibility flags
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  // Text Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  final _forgotEmailController = TextEditingController();

  // Focus Nodes
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

  // --- Validators ---

  String? _validateName(String? val) {
    final trimmed = val?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Full Name is required.';
    }
    if (trimmed.length < 3) {
      return 'Name must be at least 3 characters.';
    }
    if (trimmed.length > 50) {
      return 'Name cannot exceed 50 characters.';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      return 'Name must contain letters.';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    final trimmed = val?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Password is required.';
    }
    if (val.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please confirm your password.';
    }
    if (val != _signupPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // --- Submission Actions ---

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppSemanticColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage ?? 'Account created successfully!'),
          backgroundColor: AppSemanticColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      final user = viewModel.user;
      if (user != null) {
        context.go(user.isAdmin ? '/admin-dashboard' : '/home');
      }
    } else {
      final error = viewModel.errorMessage ?? 'Signup failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppSemanticColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_forgotFormKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.sendPasswordResetEmail(
      _forgotEmailController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.successMessage ?? 'Password reset link sent to your inbox.',
          ),
          backgroundColor: AppSemanticColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _switchMode(AuthMode.login);
    } else {
      final error = viewModel.errorMessage ?? 'Failed to send reset email.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppSemanticColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = context.watch<AuthViewModel>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLg,
                vertical: AppTheme.spaceMd,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 52,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  // Heading Title & Subtitle
                  Text(
                    _getHeaderTitle(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: AppTheme.space2xs),
                  Text(
                    _getHeaderSubtitle(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),

                  // Render Mode View Form
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

                  const SizedBox(height: AppTheme.spaceLg),

                  // Submit Action Button
                  ElevatedButton(
                    onPressed: authViewModel.isLoading
                        ? null
                        : () {
                            if (_mode == AuthMode.login) _handleLogin();
                            if (_mode == AuthMode.signup) _handleSignup();
                            if (_mode == AuthMode.forgotPassword) _handleForgotPassword();
                          },
                    child: authViewModel.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(_getSubmitButtonText()),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  // Mode Switch Links
                  _buildFooterNavigation(theme),
                ],
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
        return 'LearnLoop';
      case AuthMode.signup:
        return 'Student Sign Up';
      case AuthMode.forgotPassword:
        return 'Reset Password';
    }
  }

  String _getHeaderSubtitle() {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign in with your email and password to access your dashboard.';
      case AuthMode.signup:
        return 'Create a student account to start your learning journey.';
      case AuthMode.forgotPassword:
        return 'Enter your email address and we will send you a password reset link.';
    }
  }

  String _getSubmitButtonText() {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign In';
      case AuthMode.signup:
        return 'Create Account';
      case AuthMode.forgotPassword:
        return 'Send Reset Link';
    }
  }

  // --- Mode Form Builders ---

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _loginEmailController,
          focusNode: _loginEmailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            hintText: 'student@example.com',
          ),
          validator: _validateEmail,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_loginPasswordFocus);
          },
        ),
        const SizedBox(height: AppTheme.spaceMd),
        TextFormField(
          controller: _loginPasswordController,
          focusNode: _loginPasswordFocus,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                });
                _loginPasswordFocus.requestFocus();
              },
            ),
          ),
          validator: (val) => (val == null || val.isEmpty) ? 'Password is required.' : null,
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: AppTheme.space2xs),
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
        TextFormField(
          controller: _signupNameController,
          focusNode: _signupNameFocus,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
            hintText: 'John Doe',
          ),
          validator: _validateName,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_signupEmailFocus);
          },
        ),
        const SizedBox(height: AppTheme.spaceMd),
        TextFormField(
          controller: _signupEmailController,
          focusNode: _signupEmailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            hintText: 'student@example.com',
          ),
          validator: _validateEmail,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_signupPasswordFocus);
          },
        ),
        const SizedBox(height: AppTheme.spaceMd),
        TextFormField(
          controller: _signupPasswordController,
          focusNode: _signupPasswordFocus,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          obscureText: _obscureSignupPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            helperText: 'Must be at least 6 characters.',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscureSignupPassword = !_obscureSignupPassword;
                });
                _signupPasswordFocus.requestFocus();
              },
            ),
          ),
          validator: _validatePassword,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_signupConfirmPasswordFocus);
          },
        ),
        const SizedBox(height: AppTheme.spaceMd),
        TextFormField(
          controller: _signupConfirmPasswordController,
          focusNode: _signupConfirmPasswordFocus,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_reset_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
                _signupConfirmPasswordFocus.requestFocus();
              },
            ),
          ),
          validator: _validateConfirmPassword,
          onFieldSubmitted: (_) => _handleSignup(),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _forgotEmailController,
          focusNode: _forgotEmailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            hintText: 'Enter your registered email',
          ),
          validator: _validateEmail,
          onFieldSubmitted: (_) => _handleForgotPassword(),
        ),
      ],
    );
  }

  Widget _buildFooterNavigation(ThemeData theme) {
    if (_mode == AuthMode.login) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account?", style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: () => _switchMode(AuthMode.signup),
            child: Text(
              'Sign Up as Student',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    } else if (_mode == AuthMode.signup) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account?', style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: () => _switchMode(AuthMode.login),
            child: Text(
              'Back to Sign In',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Remembered your password?', style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: () => _switchMode(AuthMode.login),
            child: Text(
              'Back to Sign In',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }
  }
}
