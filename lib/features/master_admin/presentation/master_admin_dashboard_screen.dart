import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/coach_registry_panel.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/platform_analytics_row.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/register_gym_coach_form.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:aerofit/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterAdminDashboardScreen extends ConsumerWidget {
  const MasterAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(authStateProvider).valueOrNull?.displayName ?? 'Admin';
    final registration = ref.watch(coachRegistrationProvider);
    final isLoading =
        registration.status == CoachRegistrationStatus.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0C12),
              Color(0xFF151C2E),
              Color(0xFF0D0F14),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                title: const Text('AeroFit Platform Admin'),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () =>
                            ref.read(settingsControllerProvider).logout(),
                    child: const Text('Log out'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Welcome, $displayName',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Platform-wide analytics and live gym network management.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 24),
                    const PlatformAnalyticsRow()
                        .animate()
                        .fadeIn(delay: 120.ms)
                        .slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    _StatusBanner(state: registration),
                    if (registration.message != null) const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 960;

                        if (isWide) {
                          return const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: RegisterGymCoachForm(),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: CoachRegistryPanel(),
                              ),
                            ],
                          );
                        }

                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RegisterGymCoachForm(),
                            SizedBox(height: 20),
                            CoachRegistryPanel(),
                          ],
                        );
                      },
                    ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.04),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final CoachRegistrationState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == CoachRegistrationStatus.idle ||
        state.message == null) {
      return const SizedBox.shrink();
    }

    final isSuccess = state.status == CoachRegistrationStatus.success;
    final isError = state.status == CoachRegistrationStatus.error;
    final color = isSuccess
        ? AppColors.win
        : isError
            ? AppColors.danger
            : AppColors.primary;
    final icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : isError
            ? Icons.error_outline_rounded
            : Icons.hourglass_top_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
