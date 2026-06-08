import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _signUpName.text = Env.displayName;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    if (!FirebaseBootstrap.isReady) {
      setState(() => _errorMessage =
          'Firebase failed to initialize. Hot restart the app and try again.');
      return;
    }

    final repo = ref.read(authRepositoryProvider)!;

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

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    if (!FirebaseBootstrap.isReady) {
      setState(() => _errorMessage =
          'Firebase failed to initialize. Hot restart the app and try again.');
      return;
    }

    final repo = ref.read(authRepositoryProvider)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await repo.signUp(
        email: _signUpEmail.text,
        password: _signUpPassword.text,
        displayName: _signUpName.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Sign up failed.');
    } catch (e) {
      setState(() => _errorMessage = 'Sign up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 600 ? 420.0 : double.infinity;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    size: 48,
                    color: AppColors.primary,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
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
                          const SizedBox(height: 20),
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
                          SizedBox(
                            height: 280,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _SignInForm(
                                  formKey: _signInFormKey,
                                  email: _signInEmail,
                                  password: _signInPassword,
                                  isLoading: _isLoading,
                                  onSubmit: _signIn,
                                ),
                                _SignUpForm(
                                  formKey: _signUpFormKey,
                                  name: _signUpName,
                                  email: _signUpEmail,
                                  password: _signUpPassword,
                                  isLoading: _isLoading,
                                  onSubmit: _signUp,
                                ),
                              ],
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
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
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
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your name';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
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
