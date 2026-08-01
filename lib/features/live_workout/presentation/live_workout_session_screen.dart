import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/live_workout/data/live_workout_repository.dart';
import 'package:aerofit/features/live_workout/presentation/widgets/coach_nudge_listener.dart';
import 'package:aerofit/features/live_workout/presentation/widgets/rest_timer_modal.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveWorkoutSessionScreen extends ConsumerWidget {
  const LiveWorkoutSessionScreen({
    super.key,
    required this.exercises,
    required this.scheduleName,
  });

  final List<GymExercise> exercises;
  final String scheduleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CoachNudgeListener(
      child: _LiveWorkoutSessionBody(
        exercises: exercises,
        scheduleName: scheduleName,
      ),
    );
  }
}

class _LiveWorkoutSessionBody extends ConsumerWidget {
  const _LiveWorkoutSessionBody({
    required this.exercises,
    required this.scheduleName,
  });

  final List<GymExercise> exercises;
  final String scheduleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStatus = ref.watch(liveWorkoutStatusProvider).valueOrNull;
    final sessionIndex = ref.watch(liveWorkoutSessionIndexProvider);
    final restMinutes = ref.watch(traineeMaxRestMinutesProvider).valueOrNull ?? 3;
    final totalSets = liveStatus?.totalSets ?? LiveWorkoutRepository.defaultSetsPerExercise;

    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Workout')),
        body: const Center(child: Text('No exercises in this split.')),
      );
    }

    final currentIndex = sessionIndex.clamp(0, exercises.length - 1);
    final current = exercises[currentIndex];
    final completedIds = liveStatus?.completedWorkouts ?? const <String>[];
    final setsDone = liveStatus?.completedSets ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Workout'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(liveWorkoutControllerProvider).endSession(
                    exercisesCompleted: completedIds.length,
                    totalExercises: exercises.length,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('End'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveStatus?.routineDisplayName.isNotEmpty == true
                      ? liveStatus!.routineDisplayName
                      : scheduleName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Now: ${current.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Set ${setsDone.clamp(0, totalSets)} of $totalSets completed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.win,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: totalSets > 0
                        ? (setsDone / totalSets).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.ringTrack,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rest limit: $restMinutes min · Status: ${liveStatus?.status ?? 'working'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Today's target workouts",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            final done = completedIds.contains(exercise.id) ||
                exercise.isCompletedToday;
            final isCurrent = index == currentIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.surfaceElevated : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : const Color(0xFF252B38),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : isCurrent
                            ? Icons.play_circle_fill_rounded
                            : Icons.radio_button_unchecked_rounded,
                    color: done
                        ? AppColors.win
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration:
                                        done ? TextDecoration.lineThrough : null,
                                  ),
                        ),
                        if (exercise.weightOrSetting.isNotEmpty)
                          Text(
                            exercise.weightOrSetting,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        if (isCurrent && !done)
                          Text(
                            '$setsDone / $totalSets sets',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent && !done)
                    FilledButton(
                      onPressed: () => _completeSet(
                        context,
                        ref,
                        exercise: exercise,
                        exercises: exercises,
                        currentIndex: currentIndex,
                        completedIds: completedIds,
                        restMinutes: restMinutes,
                        totalSets: totalSets,
                        currentSetsDone: setsDone,
                      ),
                      child: const Text('Complete Set'),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _completeSet(
    BuildContext context,
    WidgetRef ref, {
    required GymExercise exercise,
    required List<GymExercise> exercises,
    required int currentIndex,
    required List<String> completedIds,
    required int restMinutes,
    required int totalSets,
    required int currentSetsDone,
  }) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(exercisesRepositoryProvider);

    final newSetsDone = currentSetsDone + 1;
    final exerciseFinished = newSetsDone >= totalSets;

    if (exerciseFinished && uid != null && repo != null) {
      await repo.setExerciseCompletedToday(
        uid: uid,
        exerciseId: exercise.id,
        completed: true,
      );
    }

    final updatedCompleted =
        exerciseFinished ? [...completedIds, exercise.id] : completedIds;
    final nextIndex = currentIndex + 1;
    final nextExercise =
        nextIndex < exercises.length ? exercises[nextIndex].name : null;

    await ref.read(liveWorkoutControllerProvider).completeSet(
          exerciseName: exercise.name,
          completedSets: newSetsDone,
          totalSets: totalSets,
          completedExerciseIds: updatedCompleted,
          nextExerciseName: nextExercise,
          exerciseFinished: exerciseFinished,
        );

    if (!context.mounted) return;

    if (exerciseFinished && nextIndex >= exercises.length) {
      await ref.read(liveWorkoutControllerProvider).endSession(
            exercisesCompleted: updatedCompleted.length,
            totalExercises: exercises.length,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout complete — session saved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    if (!exerciseFinished || nextExercise != null) {
      await showRestTimerModal(
        context: context,
        ref: ref,
        durationMinutes: restMinutes,
        nextWorkoutLabel: exerciseFinished ? nextExercise! : exercise.name,
        onStartNextSet: () {
          ref.read(liveWorkoutControllerProvider).resumeWorking(
                exerciseFinished ? nextExercise! : exercise.name,
              );
        },
      );
    }
  }
}
