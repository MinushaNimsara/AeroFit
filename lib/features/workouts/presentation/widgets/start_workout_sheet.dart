import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/live_workout/presentation/live_workout_session_screen.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showStartWorkoutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _StartWorkoutSheet(),
  );
}

class _StartWorkoutSheet extends ConsumerStatefulWidget {
  const _StartWorkoutSheet();

  @override
  ConsumerState<_StartWorkoutSheet> createState() => _StartWorkoutSheetState();
}

class _StartWorkoutSheetState extends ConsumerState<_StartWorkoutSheet> {
  String? _selectedSplitId;
  var _starting = false;

  Future<void> _confirmStart(List<WorkoutSplit> splits) async {
    final splitId = _selectedSplitId;
    if (splitId == null || _starting) return;

    final split = splits.where((s) => s.id == splitId).firstOrNull;
    if (split == null) return;

    setState(() => _starting = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      final repo = ref.read(exercisesRepositoryProvider);
      if (uid == null || repo == null) return;

      final exercises =
          await repo.watchExercisesForSplit(uid, splitId).first;

      if (exercises.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This schedule has no exercises yet.'),
          ),
        );
        return;
      }

      ref.read(selectedSplitIdProvider.notifier).state = splitId;

      await ref.read(liveWorkoutControllerProvider).startSession(
            scheduleName: split.name,
            firstExercise: exercises.first.name,
            totalExercises: exercises.length,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveWorkoutSessionScreen(
            exercises: exercises,
            scheduleName: split.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start workout: $e')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitsAsync = ref.watch(workoutSplitsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
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
          child: splitsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load schedules: $e'),
            ),
            data: (splits) {
              if (splits.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No assigned schedules yet. Ask your coach to assign a routine.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              _selectedSplitId ??= splits.first.id;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                    'Choose Today\'s Schedule',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the routine you are about to train.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...splits.map(
                    (split) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setState(() => _selectedSplitId = split.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _selectedSplitId == split.id
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedSplitId == split.id
                                    ? AppColors.primary.withValues(alpha: 0.55)
                                    : const Color(0xFF252B38),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedSplitId == split.id
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    split.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _starting ? null : () => _confirmStart(splits),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _starting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm Start'),
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
