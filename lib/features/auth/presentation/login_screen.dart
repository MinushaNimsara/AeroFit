import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/gender.dart';
import 'package:aerofit/features/auth/domain/sign_up_profile.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  bool _isLoading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    super.dispose();
  }

  bool get _busy => _isLoading || _googleLoading;

  String _firebaseUnavailableMessage() {
    if (FirebaseBootstrap.initFailed) {
      return 'Could not reach Firebase (network timed out). '
          'Try mobile data or another Wi‑Fi, then reopen the app.';
    }
    return 'Firebase is not ready yet. Close and reopen the app, then try again.';
  }

  Future<void> _signIn() async {
    final formState = _signInFormKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!FirebaseBootstrap.isReady) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await repo.signIn(
        email: _signInEmail.text,
        password: _signInPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      if (FirebaseAuth.instance.currentUser != null) return;
      final msg = switch (e.code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'invalid-email' => 'Enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        'timeout' => 'Sign in timed out. Check your internet and try again.',
        _ => e.message ?? 'Sign in failed (${e.code}).',
      };
      if (mounted) _showError(msg);
    } catch (e, stack) {
      debugPrint('Sign in error: $e\n$stack');
      if (FirebaseAuth.instance.currentUser != null) return;
      if (mounted) {
        _showError(
          e.toString().contains('TimeoutException')
              ? 'Sign in timed out. Check your internet and try again.'
              : 'Sign in failed. Check your internet and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;

    if (!FirebaseBootstrap.isReady) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      await repo.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (FirebaseAuth.instance.currentUser != null) return;
      final msg = switch (e.code) {
        'operation-not-allowed' =>
          'Google Sign-In is not enabled in Firebase Console yet.',
        'user-disabled' => 'This account has been disabled.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        'missing-id-token' =>
          e.message ?? 'Google Sign-In misconfigured (missing ID token / SHA).',
        'auth-sdk-hang' =>
          e.message ??
              'Google OK but Firebase Auth hung. Add SHA-256 + fresh google-services.json.',
        'aborted-by-user' ||
        'web-context-canceled' ||
        'cancelled-popup-request' ||
        'popup-closed-by-user' =>
          'Google Sign-In was cancelled.',
        'headful-in-progress' || 'overlapping-requests' =>
          e.message ??
              'Google Sign-In is stuck. Force-close AeroFit, reopen, try once.',
        _ => (e.message ?? '').toLowerCase().contains('initial state')
            ? 'Google Sign-In failed (browser state). Hard-refresh and try again.'
            : (e.message ?? 'Google Sign-In failed (${e.code}).'),
      };
      if (mounted &&
          e.code != 'aborted-by-user' &&
          e.code != 'web-context-canceled' &&
          e.code != 'cancelled-popup-request' &&
          e.code != 'popup-closed-by-user') {
        _showError(msg);
      }
    } catch (e, stack) {
      debugPrint('Google Sign-In error: $e\n$stack');
      if (FirebaseAuth.instance.currentUser != null) return;
      final text = e.toString();
      if (text.contains('canceled') ||
          text.contains('cancelled') ||
          text.contains('Aborte')) {
        return;
      }
      if (mounted) {
        _showError(
          text.toLowerCase().contains('initial state')
              ? 'Google Sign-In failed. Hard-refresh the page and try again.'
              : text.contains('TimeoutException')
                  ? 'Google Sign-In timed out. Check your internet.'
                  : 'Google Sign-In failed. Check internet / Firebase Google provider.',
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signUp(
    SignUpProfile profile,
    String email,
    String password,
  ) async {
    if (!mounted || _busy) return;

    if (!FirebaseBootstrap.isReady) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      _showError(_firebaseUnavailableMessage());
      return;
    }

    ref.read(authRegistrationInProgressProvider.notifier).state = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await repo
          .signUp(
            email: email.trim(),
            password: password,
            profile: profile,
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (credential.user == null &&
          FirebaseAuth.instance.currentUser == null) {
        _showError('Sign up finished but no session was created. Try Sign In.');
      }
    } on FirebaseAuthException catch (e) {
      // Auth may already be live — let router leave login.
      if (FirebaseAuth.instance.currentUser != null) return;
      final message = switch (e.code) {
        'email-already-in-use' =>
          'This email is already registered. Switch to Sign In and use your password.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        'operation-not-allowed' =>
          'Email/password sign-up is disabled in Firebase Console.',
        'registration-failed' =>
          e.message ?? 'Registration failed. Try again or use Sign In.',
        _ => e.message ?? 'Sign up failed (${e.code}).',
      };
      if (mounted) _showError(message);
    } catch (e, stack) {
      debugPrint('Sign up error: $e\n$stack');
      if (FirebaseAuth.instance.currentUser != null) return;
      if (mounted) {
        _showError(
          e.toString().contains('TimeoutException')
              ? 'Sign up timed out. If you already registered, switch to Sign In.'
              : 'Sign up failed. Check your internet and try again.',
        );
      }
    } finally {
      ref.read(authRegistrationInProgressProvider.notifier).state = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    final messenger = _scaffoldMessengerKey.currentState;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final cardWidth = isCompact ? double.infinity : 440.0;
    final horizontalPad = isCompact ? 20.0 : 28.0;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B1220),
                AppColors.background,
                Color(0xFF101820),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                isCompact ? 16 : 28,
                horizontalPad,
                isCompact ? 24 : 32,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/app_icon_source.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: AppColors.surfaceElevated,
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'AeroFit',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Train smarter. Track meals, workouts, and progress.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build 2026.10.29-v20',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2A3344)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondary,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Sign Up'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.danger.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _tabController.index == 0
                                  ? _SignInForm(
                                      key: const ValueKey('sign-in'),
                                      formKey: _signInFormKey,
                                      email: _signInEmail,
                                      password: _signInPassword,
                                      isLoading: _isLoading,
                                      googleLoading: _googleLoading,
                                      onSubmit: _signIn,
                                      onGoogle: _signInWithGoogle,
                                    )
                                  : _SignUpForm(
                                      key: const ValueKey('sign-up'),
                                      isLoading: _isLoading,
                                      onSubmit: _signUp,
                                      onShowError: _showError,
                                      onGoogle: _signInWithGoogle,
                                      googleLoading: _googleLoading,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AeroFit Build 2026.10.29-v20',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                      ),
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
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFF353D4D)),
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata_rounded, size: 28),
                  SizedBox(width: 6),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF2A3344))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF2A3344))),
      ],
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({
    super.key,
    required this.formKey,
    required this.email,
    required this.password,
    required this.isLoading,
    required this.googleLoading,
    required this.onSubmit,
    required this.onGoogle,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool isLoading;
  final bool googleLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  bool _obscurePassword = true;

  bool get _busy => widget.isLoading || widget.googleLoading;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoogleButton(
            loading: widget.googleLoading,
            enabled: !_busy,
            onPressed: widget.onGoogle,
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          _AuthTextField(
            controller: widget.email,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: widget.password,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: _busy ? null : (_) => widget.onSubmit(),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? () {} : widget.onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.background,
              ),
              child: widget.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.background,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Signing in...',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    )
                  : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: autocorrect,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: validator,
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onShowError,
    required this.onGoogle,
    required this.googleLoading,
  });

  final bool isLoading;
  final Future<void> Function(
    SignUpProfile profile,
    String email,
    String password,
  ) onSubmit;
  final void Function(String message) onShowError;
  final VoidCallback onGoogle;
  final bool googleLoading;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showValidationErrors = false;
  bool _isSubmitting = false;
  String? _activityLevelError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPasswordController.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) => widget.onShowError(message);

  String _normalizeNumericInput(String raw) {
    return raw.trim().replaceAll(',', '.');
  }

  int? _parseAgeValue(String raw) =>
      int.tryParse(_normalizeNumericInput(raw));

  double? _parseDecimalValue(String raw) =>
      double.tryParse(_normalizeNumericInput(raw));

  Future<void> _submit() async {
    if (_isSubmitting || widget.isLoading || widget.googleLoading) return;

    setState(() {
      _showValidationErrors = true;
      _activityLevelError = null;
    });

    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPasswordController.text;
    final age = _parseAgeValue(_age.text) ?? 0;
    final heightCm = _parseDecimalValue(_height.text) ?? 0;
    final weightKg = _parseDecimalValue(_weight.text) ?? 0;

    if (name.isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (age < 13 || age > 120) {
      _showSnackBar('Age must be between 13 and 120');
      return;
    }
    if (heightCm < 100 || heightCm > 250) {
      _showSnackBar('Height must be between 100 and 250 cm');
      return;
    }
    if (weightKg < 30 || weightKg > 300) {
      _showSnackBar('Weight must be between 30 and 300 kg');
      return;
    }

    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      _showSnackBar('Please check the highlighted fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        SignUpProfile(
          displayName: name,
          gender: _gender,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activityLevel: _activityLevel,
        ),
        email,
        password,
      );
    } catch (e) {
      if (FirebaseAuth.instance.currentUser != null) return;
      _showSnackBar('Registration error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your age';
    final age = _parseAgeValue(value);
    if (age == null) return 'Enter a valid age';
    if (age < 13 || age > 120) return 'Age must be between 13 and 120';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your height';
    final height = _parseDecimalValue(value);
    if (height == null) return 'Enter a valid height';
    if (height < 100 || height > 250) return 'Height must be 100–250 cm';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your weight';
    final weight = _parseDecimalValue(value);
    if (weight == null) return 'Enter a valid weight';
    if (weight < 30 || weight > 300) return 'Weight must be 30–300 kg';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isLoading || _isSubmitting || widget.googleLoading;

    return Form(
      key: _formKey,
      autovalidateMode: _showValidationErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoogleButton(
            loading: widget.googleLoading,
            enabled: !isBusy,
            onPressed: widget.onGoogle,
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          _AuthTextField(
            controller: _name,
            label: 'Full Name',
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your name';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _email,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _password,
            label: 'Password',
            hint: 'At least 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: isBusy
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: isBusy
                  ? null
                  : () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _password.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Gender',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<Gender>(
            segments: Gender.values
                .map(
                  (gender) => ButtonSegment(
                    value: gender,
                    label: Text(gender.label),
                  ),
                )
                .toList(),
            selected: {_gender},
            onSelectionChanged: isBusy
                ? null
                : (selection) {
                    if (selection.isEmpty) return;
                    setState(() => _gender = selection.first);
                  },
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _age,
            label: 'Age (years)',
            hint: 'e.g. 25',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateAge,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _height,
            label: 'Height (cm)',
            hint: 'e.g. 175',
            icon: Icons.height_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
            ],
            validator: _validateHeight,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _weight,
            label: 'Weight (kg)',
            hint: 'e.g. 70',
            icon: Icons.monitor_weight_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
            ],
            validator: _validateWeight,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Activity level',
              prefixIcon: const Icon(Icons.directions_run_outlined),
              errorText: _activityLevelError,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActivityLevel>(
                isExpanded: true,
                value: _activityLevel,
                items: ActivityLevel.values
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(
                          level.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isBusy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _activityLevel = value;
                          _activityLevelError = null;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              // Keep primary styling while busy — disabled M3 style paints a
              // near-invisible spinner that looks like a lone "-" on dark UI.
              onPressed: isBusy ? () {} : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.background,
              ),
              child: (widget.isLoading || _isSubmitting)
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.background,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Creating account...',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    )
                  : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
