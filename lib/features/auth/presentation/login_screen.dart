import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/gender.dart';
import 'package:aerofit/features/auth/domain/sign_up_profile.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _signUpFormKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (!_tabController.indexIsChanging) {
          _errorMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final formState = _signInFormKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!FirebaseBootstrap.isReady) {
      setState(() => _errorMessage =
          'Firebase failed to initialize. Hot restart the app and try again.');
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      setState(() => _errorMessage =
          'Firebase failed to initialize. Hot restart the app and try again.');
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
      setState(() => _errorMessage = e.message ?? 'Sign in failed.');
    } catch (e) {
      setState(() => _errorMessage = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp(SignUpProfile profile, String email, String password) async {
    if (!mounted) return;

    ref.read(authRegistrationInProgressProvider.notifier).state = true;

    try {
      if (!FirebaseBootstrap.isReady) {
        _showErrorSnackBar(
          'Firebase failed to initialize. Hot restart the app and try again.',
        );
        return;
      }

      final repo = ref.read(authRepositoryProvider);
      if (repo == null) {
        _showErrorSnackBar(
          'Firebase failed to initialize. Hot restart the app and try again.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await repo.signUp(
        email: email.trim(),
        password: password,
        profile: profile,
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' =>
          'This email is already registered. Switch to Sign In and log in instead.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        _ => e.message ?? 'Sign up failed (${e.code}).',
      };
      if (mounted) {
        _showErrorSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      ref.read(authRegistrationInProgressProvider.notifier).state = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);

    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final cardWidth = isCompact ? double.infinity : 420.0;
    final horizontalPad = isCompact ? 16.0 : 24.0;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            isCompact ? 12 : 20,
            horizontalPad,
            isCompact ? 20 : 24,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    size: 40,
                    color: AppColors.primary,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 8),
                  Text(
                    'AeroFit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to track your routine, meals, and gym.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.primary,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                    onSubmit: _signIn,
                                  )
                                : _SignUpForm(
                                    key: const ValueKey('sign-up'),
                                    formKey: _signUpFormKey,
                                    isLoading: _isLoading,
                                    onSubmit: _signUp,
                                    onShowError: _showErrorSnackBar,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.05, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
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
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 10),
          _AuthTextField(
            controller: widget.password,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: widget.isLoading ? null : (_) => widget.onSubmit(),
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
          const SizedBox(height: 14),
          FilledButton(
            onPressed: widget.isLoading ? null : widget.onSubmit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Text('Sign In'),
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
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      validator: validator,
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.onSubmit,
    required this.onShowError,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final Future<void> Function(SignUpProfile profile, String email, String password)
      onSubmit;
  final void Function(String message) onShowError;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
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

  int? _parseAgeValue(String raw) {
    return int.tryParse(_normalizeNumericInput(raw));
  }

  double? _parseDecimalValue(String raw) {
    return double.tryParse(_normalizeNumericInput(raw));
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.isLoading) return;

    setState(() {
      _showValidationErrors = true;
      _isSubmitting = true;
    });

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(Duration.zero);

      final formState = widget.formKey.currentState;
      if (formState == null) {
        _showSnackBar('Form is not ready. Please try again.');
        return;
      }

      late final bool isValid;
      try {
        isValid = formState.validate();
      } catch (e) {
        _showSnackBar('Could not validate the form: $e');
        return;
      }
      if (!isValid) {
        _showSnackBar('Please fix the highlighted fields and try again.');
        return;
      }

      if (_password.text.trim() != _confirmPasswordController.text.trim()) {
        _showSnackBar('Passwords do not match');
        return;
      }

      final age = _parseAgeValue(_age.text) ?? 0;
      final heightCm = _parseDecimalValue(_height.text) ?? 0;
      final weightKg = _parseDecimalValue(_weight.text) ?? 0;

      if (age <= 0) {
        _showSnackBar('Enter a valid age');
        return;
      }
      if (heightCm <= 0) {
        _showSnackBar('Enter a valid height');
        return;
      }
      if (weightKg <= 0) {
        _showSnackBar('Enter a valid weight');
        return;
      }

      final activityLevel = _resolveActivityLevel(_activityLevel);
      if (!ActivityLevel.values.contains(activityLevel)) {
        setState(() => _activityLevelError = 'Select a valid activity level');
        _showSnackBar('Select a valid activity level');
        return;
      }
      setState(() => _activityLevelError = null);

      await widget.onSubmit(
        SignUpProfile(
          displayName: _name.text.trim(),
          gender: _gender,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activityLevel: activityLevel,
        ),
        _email.text.trim(),
        _password.text,
      );
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ActivityLevel _resolveActivityLevel(ActivityLevel level) {
    return ActivityLevel.values.contains(level) ? level : ActivityLevel.sedentary;
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
    final isBusy = widget.isLoading || _isSubmitting;

    return Form(
      key: widget.formKey,
      autovalidateMode: _showValidationErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Confirm your password';
              }
              if (v != _password.text) {
                return 'Passwords do not match';
              }
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
          const SizedBox(height: 14),
          _AuthTextField(
            controller: _age,
            label: 'Age (years)',
            hint: 'e.g. 25',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateAge,
          ),
          const SizedBox(height: 14),
          _AuthTextField(
            controller: _height,
            label: 'Height (cm)',
            hint: 'e.g. 175',
            icon: Icons.height_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateHeight,
          ),
          const SizedBox(height: 14),
          _AuthTextField(
            controller: _weight,
            label: 'Weight (kg)',
            hint: 'e.g. 70',
            icon: Icons.monitor_weight_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateWeight,
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
