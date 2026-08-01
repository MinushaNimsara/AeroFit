import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterGymCoachForm extends ConsumerStatefulWidget {
  const RegisterGymCoachForm({super.key});

  @override
  ConsumerState<RegisterGymCoachForm> createState() =>
      _RegisterGymCoachFormState();
}

class _RegisterGymCoachFormState extends ConsumerState<RegisterGymCoachForm> {
  final _formKey = GlobalKey<FormState>();
  final _gymName = TextEditingController();
  final _coachName = TextEditingController();
  final _coachEmail = TextEditingController();
  final _coachPassword = TextEditingController();

  @override
  void dispose() {
    _gymName.dispose();
    _coachName.dispose();
    _coachEmail.dispose();
    _coachPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(coachRegistrationProvider.notifier).registerGymAndCoach(
          gymName: _gymName.text,
          coachFullName: _coachName.text,
          coachEmail: _coachEmail.text,
          coachPassword: _coachPassword.text,
        );
  }

  void _clearForm() {
    _gymName.clear();
    _coachName.clear();
    _coachEmail.clear();
    _coachPassword.clear();
    ref.read(coachRegistrationProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final registration = ref.watch(coachRegistrationProvider);
    final isLoading =
        registration.status == CoachRegistrationStatus.loading;

    ref.listen<CoachRegistrationState>(coachRegistrationProvider, (_, next) {
      if (next.status == CoachRegistrationStatus.success) {
        _coachPassword.clear();
      }
    });

    return Card(
      color: AppColors.surfaceElevated,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.surfaceElevated,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Register New Gym & Coach',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Creates a dedicated coach login without signing you out.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _gymName,
                textCapitalization: TextCapitalization.words,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Gym Name',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter the gym name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _coachName,
                textCapitalization: TextCapitalization.words,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Coach Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter the coach name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _coachEmail,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Coach Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter the coach email';
                  }
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _coachPassword,
                obscureText: true,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Coach Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Gym & Coach'),
              ),
              if (registration.status == CoachRegistrationStatus.success) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isLoading ? null : _clearForm,
                  child: const Text('Register Another'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
