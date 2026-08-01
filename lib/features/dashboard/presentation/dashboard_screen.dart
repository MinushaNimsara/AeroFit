import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/daily_goal_ring.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/daily_win_loss_banner.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/remaining_tasks_card.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/status_pill_row.dart';
import 'package:aerofit/features/dashboard/providers/dashboard_providers.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/gym_membership_banner.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/gym_pass_card.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:aerofit/features/routine/providers/tasks_providers.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
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

    return Scaffold(
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('Could not load dashboard: $e'),
          ),
          data: (status) => _DashboardBody(
            displayName: displayName,
            dateLabel: dateLabel,
            status: status,
            onRefresh: () async {
              ref.invalidate(tasksStreamProvider);
              ref.invalidate(todayMealsStreamProvider);
              ref.invalidate(todayExercisesStreamProvider);
              ref.invalidate(dailyStatusProvider);
            },
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
  });

  final String displayName;
  final String dateLabel;
  final DailyStatus status;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text(
                  'Welcome $displayName',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 450.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Your daily hub — routine, fuel, and training in one place.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 400.ms),
                const SizedBox(height: 20),
                const GymMembershipBanner()
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 450.ms),
                const SizedBox(height: 16),
                const GymPassCard()
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 450.ms),
                const SizedBox(height: 24),
                DailyWinLossBanner(
                  isWin: status.isDailyWin,
                  calorieGoal: status.calorieGoal,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Center(
                  child: DailyGoalRing(progress: status.goalProgress)
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 550.ms),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${(status.goalProgress * 100).round()}% of daily goals',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                StatusPillRow(status: status),
                const SizedBox(height: 20),
                RemainingTasksCard(
                  completed: status.tasksCompleted,
                  total: status.tasksTotal,
                  caloriesRemaining: status.caloriesRemaining,
                  calorieGoal: status.calorieGoal,
                ),
                const SizedBox(height: 20),
                _QuickActions(context: context),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick log',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.restaurant_rounded,
                label: 'Log meal',
                onTap: () => context.go('/meals'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Icons.fitness_center_rounded,
                label: 'Gym set',
                onTap: () => context.go('/workouts'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Task',
                onTap: () => context.go('/routine'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
