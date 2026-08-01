import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterAdminLoginScreen extends ConsumerStatefulWidget {
  const MasterAdminLoginScreen({super.key});

  @override
  ConsumerState<MasterAdminLoginScreen> createState() =>
      _MasterAdminLoginScreenState();
}

class _MasterAdminLoginScreenState
    extends ConsumerState<MasterAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ref.read(masterAdminLoginControllerProvider).signIn(
          email: _email.text,
          password: _password.text,
        );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0C12),
              Color(0xFF12182A),
              Color(0xFF0D0F14),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.35),
                            AppColors.accent.withValues(alpha: 0.15),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_moon_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(
                          begin: const Offset(0.9, 0.9),
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'Master Admin Portal',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Restricted access — platform operators only.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 32),
                    Card(
                      color: AppColors.surfaceElevated,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.4),
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
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Admin email',
                                  prefixIcon: Icon(Icons.admin_panel_settings),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your admin email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
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
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign In to Admin Portal'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.05),
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
