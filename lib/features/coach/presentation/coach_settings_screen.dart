import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/coach/presentation/widgets/coach_rest_limit_card.dart';
import 'package:aerofit/features/enrollment/presentation/enroll_scanner_screen.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/enroll_member_card.dart';
import 'package:aerofit/features/enrollment/providers/gym_enrollment_providers.dart';
import 'package:aerofit/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CoachSettingsScreen extends ConsumerStatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  ConsumerState<CoachSettingsScreen> createState() =>
      _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends ConsumerState<CoachSettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(settingsControllerProvider).logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _openScanner() async {
    ref.read(enrollmentScanProvider.notifier).reset();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const EnrollScannerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final gymName = profile?.gymName?.trim();
    final displayName = profile?.displayName ?? 'Coach';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0C12), Color(0xFF151C2E), Color(0xFF0D0F14)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/coach/dashboard'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Coach Settings',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              if (gymName != null && gymName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  gymName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              EnrollMemberCard(onScan: _openScanner),
              const SizedBox(height: 20),
              const CoachRestLimitCard(),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(_isLoggingOut ? 'Signing out…' : 'Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
