import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/coach/presentation/widgets/assign_routine_dialog.dart';
import 'package:aerofit/features/coach/presentation/widgets/set_trainee_calories_dialog.dart';
import 'package:aerofit/features/coach/domain/trainee_profile_snapshot.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:aerofit/features/live_workout/domain/live_workout_status.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:aerofit/shared/widgets/edit_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Future<void> showTraineeProfileSheet(
  BuildContext context,
  String traineeUid,
  String traineeName,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TraineeProfileSheet(
      traineeUid: traineeUid,
      traineeName: traineeName,
    ),
  );
}

class TraineeProfileSheet extends ConsumerWidget {
  const TraineeProfileSheet({
    super.key,
    required this.traineeUid,
    required this.traineeName,
  });

  final String traineeUid;
  final String traineeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(traineeProfileProvider(traineeUid));
    final timeFormat = DateFormat.jm();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF252B38)),
              left: BorderSide(color: Color(0xFF252B38)),
              right: BorderSide(color: Color(0xFF252B38)),
            ),
          ),
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load profile: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            data: (snapshot) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.displayName.isNotEmpty
                        ? snapshot.displayName
                        : traineeName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Daily overview & compliance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryRow(
                    snapshot: snapshot,
                    traineeUid: traineeUid,
                    traineeName: snapshot.displayName.isNotEmpty
                        ? snapshot.displayName
                        : traineeName,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showAssignRoutineDialog(
                        context,
                        traineeUid: traineeUid,
                        traineeName: snapshot.displayName.isNotEmpty
                            ? snapshot.displayName
                            : traineeName,
                      );
                    },
                    icon: const Icon(Icons.event_note_rounded),
                    label: const Text('Assign Schedule'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Live Workout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _LiveWorkoutSection(traineeUid: traineeUid),
                  const SizedBox(height: 20),
                  _WorkoutHistorySection(traineeUid: traineeUid),
                  const SizedBox(height: 20),
                  Text(
                    "Today's Meals",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.meals.isEmpty)
                    const _EmptyBlock(
                      message: 'No meals logged today.',
                    )
                  else
                    ...snapshot.meals.map(
                      (meal) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF252B38)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${meal.mealType} · ${timeFormat.format(meal.timestamp)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${meal.calories} kcal',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Routine Compliance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.tasks.isEmpty)
                    const _EmptyBlock(
                      message: 'No daily routine tasks set.',
                    )
                  else
                    ...snapshot.tasks.map(
                      (task) => CheckboxListTile(
                        value: task.isCompleted,
                        onChanged: null,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(task.title),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.win,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow({
    required this.snapshot,
    required this.traineeUid,
    required this.traineeName,
  });

  final TraineeProfileSnapshot snapshot;
  final String traineeUid;
  final String traineeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Calories',
            value: '${snapshot.caloriesConsumed}/${snapshot.calorieGoal}',
            onEdit: () => showSetTraineeCaloriesDialog(
              context: context,
              ref: ref,
              traineeUid: traineeUid,
              traineeName: traineeName,
              currentGoal: snapshot.calorieGoal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'Routine',
            value: snapshot.routineComplete
                ? 'Complete'
                : '${snapshot.tasksCompleted}/${snapshot.tasks.length}',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit calorie target',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2A3344),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  icon: const EditIcon(
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveWorkoutSection extends ConsumerWidget {
  const _LiveWorkoutSection({required this.traineeUid});

  final String traineeUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(traineeLiveStatusProvider(traineeUid));

    return statusAsync.when(
      loading: () => const _EmptyBlock(
        message: 'Checking live gym session…',
      ),
      error: (e, _) => _EmptyBlock(
        message: 'Could not load live status: $e',
      ),
      data: (status) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LiveWorkoutCard(status: status),
            const SizedBox(height: 12),
            _NudgeTraineeButton(
              traineeUid: traineeUid,
              enabled: status.isWorkingOut,
              emphasized: status.isSlacking,
            ),
          ],
        );
      },
    );
  }
}

class _LiveWorkoutCard extends StatelessWidget {
  const _LiveWorkoutCard({
    required this.status,
  });

  final LiveWorkoutStatus status;

  @override
  Widget build(BuildContext context) {
    if (!status.isWorkingOut) {
      return const _EmptyBlock(message: 'Not in an active gym session.');
    }

    if (status.isSlacking) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Slacking — rest timer exceeded',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
            if (status.routineDisplayName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                status.routineDisplayName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (status.hasSetProgress) ...[
              const SizedBox(height: 12),
              _LiveSetTracker(status: status),
            ],
            if (status.startedAt != null) ...[
              const SizedBox(height: 8),
              _ElapsedTimer(startedAt: status.startedAt!),
            ],
          ],
        ),
      );
    }

    final routineName = status.routineDisplayName;
    final headline = routineName.isNotEmpty
        ? '🔥 Training Live: $routineName'
        : '🔥 Training Live';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.win.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.win.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.win.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.win,
              fontSize: 15,
            ),
          ),
          if (status.isResting) ...[
            const SizedBox(height: 6),
            Text(
              'Resting between sets',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (status.hasSetProgress) ...[
            const SizedBox(height: 12),
            _LiveSetTracker(status: status),
          ],
          if (status.startedAt != null) ...[
            const SizedBox(height: 10),
            _ElapsedTimer(startedAt: status.startedAt!),
          ],
        ],
      ),
    );
  }
}

class _LiveSetTracker extends StatelessWidget {
  const _LiveSetTracker({required this.status});

  final LiveWorkoutStatus status;

  @override
  Widget build(BuildContext context) {
    final exercise = status.activeExerciseLabel;
    final completed = status.completedSets.clamp(0, status.totalSets);
    final total = status.totalSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔥 Current: $exercise — Set $completed of $total Completed',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: status.setProgressFraction,
            minHeight: 8,
            backgroundColor: AppColors.ringTrack,
            color: status.isSlacking ? AppColors.warning : AppColors.win,
          ),
        ),
      ],
    );
  }
}

class _NudgeTraineeButton extends ConsumerStatefulWidget {
  const _NudgeTraineeButton({
    required this.traineeUid,
    this.enabled = true,
    this.emphasized = false,
  });

  final String traineeUid;
  final bool enabled;
  final bool emphasized;

  @override
  ConsumerState<_NudgeTraineeButton> createState() => _NudgeTraineeButtonState();
}

class _NudgeTraineeButtonState extends ConsumerState<_NudgeTraineeButton> {
  var _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(coachTraineeControllerProvider)
          .nudgeTrainee(widget.traineeUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nudge sent — trainee alerted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send nudge: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && !_sending;
    final accent = widget.emphasized
        ? AppColors.warning
        : AppColors.warning.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: canSend ? _send : null,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.emphasized
                      ? Icons.bolt_rounded
                      : Icons.notifications_active_rounded,
                ),
          label: const Text('Zap / Nudge Trainee'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: widget.emphasized
                ? AppColors.warning.withValues(alpha: 0.28)
                : AppColors.warning.withValues(alpha: 0.14),
            foregroundColor: accent,
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.textSecondary,
            side: BorderSide(
              color: widget.emphasized
                  ? AppColors.warning.withValues(alpha: 0.85)
                  : AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
        ),
        if (!widget.enabled) ...[
          const SizedBox(height: 6),
          Text(
            'Nudge unlocks when the trainee starts a live gym session.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _WorkoutHistorySection extends ConsumerWidget {
  const _WorkoutHistorySection({required this.traineeUid});

  final String traineeUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(traineeWorkoutHistoryProvider(traineeUid));
    final dateFormat = DateFormat.MMMd();
    final timeFormat = DateFormat.jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Workout History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (e, _) => _EmptyBlock(
            message: 'Could not load workout history: $e',
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const _EmptyBlock(
                message: 'No completed gym sessions recorded yet.',
              );
            }

            return Column(
              children: sessions.map((session) {
                final when = '${dateFormat.format(session.endedAt)} · '
                    '${timeFormat.format(session.endedAt)}';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
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
                        session.routineName.isNotEmpty
                            ? session.routineName
                            : 'Gym Session',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${session.exercisesCompleted} / ${session.totalExercises} exercises · ${session.durationMinutes} min active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        when,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late final Stream<int> _tickStream;

  @override
  void initState() {
    super.initState();
    _tickStream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => count,
    );
  }

  String _formatElapsed() {
    final elapsed = DateTime.now().difference(widget.startedAt);
    if (elapsed.isNegative) return '00:00:00';

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _tickStream,
      builder: (context, _) {
        return Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: AppColors.win.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              _formatElapsed(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.win,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'elapsed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
