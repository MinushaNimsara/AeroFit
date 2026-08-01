import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/gym_pass_card.dart';
import 'package:aerofit/features/settings/presentation/widgets/report_issue_dialog.dart';
import 'package:aerofit/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isResettingPassword = false;
  bool _isLoggingOut = false;

  Future<void> _resetPassword() async {
    setState(() => _isResettingPassword = true);
    try {
      await ref.read(settingsControllerProvider).sendPasswordResetEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final email = user?.email ?? '';
    final isCompact = MediaQuery.sizeOf(context).width < 900;
    final horizontalPad = isCompact ? 16.0 : 20.0;

    return Scaffold(
      appBar: isCompact
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              title: const Text('Settings'),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            isCompact ? 8 : 16,
            horizontalPad,
            32,
          ),
          children: [
            if (!isCompact) ...[
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                email.isNotEmpty ? email : 'Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                email.isNotEmpty ? email : 'Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            const GymPassCard(),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Reset Password'),
                    subtitle: const Text(
                      'Send a password reset link to your email',
                    ),
                    trailing: _isResettingPassword
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _isResettingPassword ? null : _resetPassword,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.report_gmailerrorred_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Report an Issue'),
                    subtitle: const Text('Tell us what went wrong'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: email.isEmpty
                        ? null
                        : () => showReportIssueDialog(
                              context,
                              ref,
                              userEmail: email,
                            ),
                  ),
                ],
              ),
            ),
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
    );
  }
}
