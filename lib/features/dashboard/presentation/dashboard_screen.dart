import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/daily_win_loss_banner.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/status_pill_row.dart';
import 'package:aerofit/features/dashboard/providers/dashboard_providers.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/gym_membership_banner.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:aerofit/features/routine/providers/tasks_providers.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/shared/widgets/settings_gear_button.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (authUid == null || authUid.trim().isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final statusAsync = ref.watch(dailyStatusProvider);
    final displayName = ref.watch(displayNameProvider);
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    Future<void> refresh() async {
      ref.invalidate(tasksStreamProvider);
      ref.invalidate(todayMealsStreamProvider);
      ref.invalidate(todayExercisesStreamProvider);
      ref.invalidate(dailyStatusProvider);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: statusAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => _DashboardBody(
              displayName: displayName,
              dateLabel: dateLabel,
              status: DailyStatus.empty(),
              offlineHint: true,
              onRefresh: refresh,
            ),
            data: (status) => _DashboardBody(
              displayName: displayName,
              dateLabel: dateLabel,
              status: status,
              onRefresh: refresh,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.displayName,
    required this.dateLabel,
    required this.status,
    required this.onRefresh,
    this.offlineHint = false,
  });

  final String displayName;
  final String dateLabel;
  final DailyStatus status;
  final Future<void> Function() onRefresh;
  final bool offlineHint;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              12,
              AppSpacing.screen,
              24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GreetingCard(displayName: displayName, dateLabel: dateLabel)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
                if (offlineHint) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadii.tileBr,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Cloud sync is offline. Showing a local dashboard — pull down to retry when internet is back.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Gym Pass QR lives in Settings only — Hub shows join CTA banner.
                const GymMembershipBanner()
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 450.ms),
                const SizedBox(height: AppSpacing.section),
                SectionHeader(
                  title: 'Health Overview',
                  actionLabel: 'See all',
                  onAction: () => context.go('/reports'),
                ),
                StatusPillRow(status: status)
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 450.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.section),
                const SectionHeader(title: 'Daily Goals'),
                DailyWinLossBanner(
                  isWin: status.isDailyWin,
                  calorieGoal: status.calorieGoal,
                  progress: status.goalProgress,
                ).animate().fadeIn(delay: 220.ms, duration: 500.ms).scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.section),
                const SectionHeader(title: 'Quick Actions'),
                const _QuickActions()
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 450.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.displayName, required this.dateLabel});

  final String displayName;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName.trim();
    final initial = trimmed.isEmpty ? 'A' : trimmed[0].toUpperCase();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      color: AppColors.surface.withValues(alpha: 0.85),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: AppRadii.tileBr,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.35),
                  AppColors.surfaceHighest,
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $displayName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SettingsGearButton(),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionTile(
            icon: Icons.restaurant_rounded,
            color: AppColors.accent,
            label: 'Log meal',
            onTap: () => context.go('/meals'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ActionTile(
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            label: 'Gym set',
            onTap: () => context.go('/workouts'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ActionTile(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.info,
            label: 'Task',
            onTap: () => context.go('/routine'),
          ),
        ),
      ],
    );
  }
}
