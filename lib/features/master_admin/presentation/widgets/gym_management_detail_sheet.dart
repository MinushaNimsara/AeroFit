import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/domain/coach_workout_schedule.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/clone_schedule_dialog.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/registry_shimmer.dart';
import 'package:aerofit/features/master_admin/providers/gym_detail_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void showGymManagementDetailSheet(
  BuildContext context,
  WidgetRef ref,
  CoachRegistryEntry gym,
) {
  ref.read(gymDetailTabProvider.notifier).state = 0;
  ref.read(selectedGymProvider.notifier).state = gym;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return _GymManagementDetailSheet(gym: gym);
      },
    ),
  ).whenComplete(() {
    ref.read(selectedGymProvider.notifier).state = null;
  });
}

class _GymManagementDetailSheet extends ConsumerStatefulWidget {
  const _GymManagementDetailSheet({required this.gym});

  final CoachRegistryEntry gym;

  @override
  ConsumerState<_GymManagementDetailSheet> createState() =>
      _GymManagementDetailSheetState();
}

class _GymManagementDetailSheetState
    extends ConsumerState<_GymManagementDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(gymDetailTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traineeCountAsync =
        ref.watch(activeGymTraineeCountProvider(widget.gym.gymName));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF10141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: Color(0xFF2A3142)),
          left: BorderSide(color: Color(0xFF2A3142)),
          right: BorderSide(color: Color(0xFF2A3142)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gym.gymName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coach: ${widget.gym.coachName} · ${widget.gym.email}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: traineeCountAsync.when(
              loading: () => const _GymMetricStrip(activeTrainees: '—'),
              error: (_, __) => const _GymMetricStrip(activeTrainees: '—'),
              data: (count) => _GymMetricStrip(activeTrainees: '$count'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Trainees & Progress'),
                Tab(text: 'Coach Workout Schedules'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TraineesTab(gymName: widget.gym.gymName),
                _SchedulesTab(gym: widget.gym),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GymMetricStrip extends StatelessWidget {
  const _GymMetricStrip({required this.activeTrainees});

  final String activeTrainees;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeTrainees,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Active Gym Trainees',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TraineesTab extends ConsumerWidget {
  const _TraineesTab({required this.gymName});

  final String gymName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traineesAsync = ref.watch(gymTraineeProgressProvider(gymName));
    final dateFormat = DateFormat('MMM d, h:mm a');

    return traineesAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Trainee Progress Tracker',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          RegistryShimmer(rowCount: 4),
        ],
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load trainees: $e',
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
      data: (trainees) {
        if (trainees.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Trainee Progress Tracker',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Text(
                  'No trainees are linked to this gym yet. Trainees need `gymName` set to "${gymName.trim()}".',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: trainees.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Trainee Progress Tracker',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              );
            }

            final trainee = trainees[index - 1];
            final lastActive = trainee.lastActiveAt != null
                ? dateFormat.format(trainee.lastActiveAt!)
                : 'No activity logged yet';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF252B38)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainee.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: trainee.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.ringTrack,
                            color: trainee.caloriesConsumed > trainee.calorieGoal
                                ? AppColors.danger
                                : AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${trainee.caloriesConsumed} / ${trainee.calorieGoal} kcal',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last active: $lastActive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SchedulesTab extends ConsumerWidget {
  const _SchedulesTab({required this.gym});

  final CoachRegistryEntry gym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(coachWorkoutSchedulesProvider(gym.uid));

    return schedulesAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Coach Workout Schedules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          RegistryShimmer(rowCount: 3),
        ],
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load schedules: $e',
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
      data: (schedules) {
        if (schedules.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Coach Workout Schedules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Text(
                  'This coach has not created any workout schedules yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: schedules.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Coach Workout Schedules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              );
            }

            final schedule = schedules[index - 1];
            return _ScheduleCard(
              gym: gym,
              schedule: schedule,
            );
          },
        );
      },
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({
    required this.gym,
    required this.schedule,
  });

  final CoachRegistryEntry gym;
  final CoachWorkoutSchedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloneState = ref.watch(scheduleCloneProvider);
    final isCloning = cloneState.status == ScheduleCloneStatus.loading;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${schedule.totalDays} day${schedule.totalDays == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (schedule.workoutPreview.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: schedule.workoutPreview
                  .map(
                    (workout) => Chip(
                      label: Text(workout),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          AppColors.surfaceElevated.withValues(alpha: 0.8),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'No workout preview available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isCloning
                  ? null
                  : () => showCloneScheduleDialog(
                        context: context,
                        ref: ref,
                        sourceGym: gym,
                        schedule: schedule,
                      ),
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('Copy to Another Gym'),
            ),
          ),
        ],
      ),
    );
  }
}
