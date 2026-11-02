import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_demo_stage.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/enrollment/presentation/widgets/gym_membership_banner.dart';
import 'package:aerofit/features/enrollment/providers/gym_enrollment_providers.dart';
import 'package:aerofit/features/live_workout/presentation/live_workout_session_screen.dart';
import 'package:aerofit/features/workouts/presentation/widgets/start_workout_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:aerofit/features/workouts/presentation/widgets/add_exercise_sheet.dart';
import 'package:aerofit/features/workouts/presentation/widgets/workout_splits_header.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (authUid == null || authUid.trim().isEmpty) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final isCompactViewport = MediaQuery.sizeOf(context).shortestSide < 600;
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final isTrainee = profile?.isTrainee ?? false;
    final enrolled = ref.watch(isTraineeEnrolledProvider);
    final splitsAsync = ref.watch(workoutSplitsStreamProvider);
    final exercisesAsync = ref.watch(splitExercisesStreamProvider);
    final selectedSplitId = ref.watch(effectiveSelectedSplitIdProvider);
    final progress = ref.watch(activeSplitGymProgressProvider);

    // Trainees can always build their own splits/routines from the exercise
    // library and track workouts — gym enrollment only unlocks live
    // coach-connected features (coach-assigned schedules, live session
    // visibility to a coach), shown via the banner below.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        actions: [
          IconButton(
            tooltip: 'Exercise Library',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => context.push('/workouts/library'),
          ),
          if (progress.$2 > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${progress.$1}/${progress.$2}',
                    style: TextStyle(
                      color: progress.$1 == progress.$2
                          ? AppColors.win
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          // Reserve space for AppShell's floating SettingsGearButton
          // (44px wide, positioned right: 12) so actions don't overlap it.
          const SizedBox(width: 56),
        ],
      ),
      floatingActionButton: splitsAsync.maybeWhen(
        data: (splits) {
          if (splits.isEmpty || selectedSplitId == null) {
            return null;
          }
          return FloatingActionButton.extended(
            onPressed: () => showAddExerciseSheet(
              context,
              splitId: selectedSplitId,
              splits: splits,
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            elevation: 2,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Exercise'),
          );
        },
        orElse: () => null,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isCompactViewport ? double.infinity : 1100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isTrainee && !enrolled)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: GymMembershipBanner(),
                ),
              const WorkoutSplitsHeader(),
              _StartWorkoutBanner(
                exercisesAsync: exercisesAsync,
                splitsAsync: splitsAsync,
                selectedSplitId: selectedSplitId,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: exercisesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load exercises: $e',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (exercises) {
                    final splits = splitsAsync.valueOrNull;
                    if (splits == null || splits.isEmpty || selectedSplitId == null) {
                      return const SizedBox.shrink();
                    }
                    return _GymBody(
                      exercises: exercises,
                      splitName: splits
                          .where((s) => s.id == selectedSplitId)
                          .map((s) => s.name)
                          .firstOrNull,
                      onDelete: (exercise) => _deleteExercise(ref, exercise),
                      onToggleComplete: (exercise, completed) =>
                          _toggleExerciseComplete(ref, exercise, completed),
                      onReorder: (orderedIds) =>
                          _reorderExercises(ref, orderedIds),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleExerciseComplete(
    WidgetRef ref,
    GymExercise exercise,
    bool completed,
  ) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(exercisesRepositoryProvider);
    if (uid == null || repo == null) return;
    await repo.setExerciseCompletedToday(
      uid: uid,
      exerciseId: exercise.id,
      completed: completed,
    );
  }

  Future<void> _deleteExercise(WidgetRef ref, GymExercise exercise) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(exercisesRepositoryProvider);
    if (uid == null || repo == null) return;
    await repo.deleteExercise(uid: uid, exerciseId: exercise.id);
  }

  Future<void> _reorderExercises(
    WidgetRef ref,
    List<String> orderedIds,
  ) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(exercisesRepositoryProvider);
    if (uid == null || repo == null) return;
    await repo.reorderExercises(uid: uid, orderedIds: orderedIds);
  }
}

class _StartWorkoutBanner extends ConsumerWidget {
  const _StartWorkoutBanner({
    required this.exercisesAsync,
    required this.splitsAsync,
    required this.selectedSplitId,
  });

  final AsyncValue<List<GymExercise>> exercisesAsync;
  final AsyncValue<List<WorkoutSplit>> splitsAsync;
  final String? selectedSplitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStatus = ref.watch(liveWorkoutStatusProvider).valueOrNull;
    final exercises = exercisesAsync.valueOrNull ?? const <GymExercise>[];
    final splits = splitsAsync.valueOrNull;
    final splitName = splits
            ?.where((s) => s.id == selectedSplitId)
            .map((s) => s.name)
            .firstOrNull ??
        'Today\'s Workout';

    if (selectedSplitId == null || splits == null || splits.isEmpty) {
      return const SizedBox.shrink();
    }

    final exerciseCount = exercises.length;
    final inSession = liveStatus?.isWorkingOut == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              inSession ? 'Session in progress' : 'Ready to train?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              inSession
                  ? 'Current: ${liveStatus?.activeExerciseLabel ?? splitName}'
                  : exerciseCount > 0
                      ? '$exerciseCount exercises · $splitName'
                      : 'Add exercises to $splitName, then start',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                if (inSession && exerciseCount > 0) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LiveWorkoutSessionScreen(
                        exercises: exercises,
                        scheduleName:
                            liveStatus!.routineDisplayName.isNotEmpty
                                ? liveStatus.routineDisplayName
                                : splitName,
                      ),
                    ),
                  );
                  return;
                }

                await showStartWorkoutSheet(context);
              },
              icon: Icon(
                inSession ? Icons.play_arrow_rounded : Icons.bolt_rounded,
              ),
              label: Text(
                inSession ? 'Resume Session' : 'Start Workout Session',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymBody extends StatelessWidget {
  const _GymBody({
    required this.exercises,
    required this.splitName,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onReorder,
  });

  final List<GymExercise> exercises;
  final String? splitName;
  final void Function(GymExercise exercise) onDelete;
  final void Function(GymExercise exercise, bool completed) onToggleComplete;
  final void Function(List<String> orderedIds) onReorder;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                splitName != null
                    ? 'No exercises in "$splitName" yet'
                    : 'No exercises in this split',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add exercises with machine photos so you never forget your settings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            return Material(
              elevation: 1 + 4 * t,
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: child,
        );
      },
      itemCount: exercises.length,
      onReorder: (oldIndex, newIndex) {
        var insertAt = newIndex;
        if (insertAt > oldIndex) insertAt -= 1;
        final next = List<GymExercise>.of(exercises);
        final moved = next.removeAt(oldIndex);
        next.insert(insertAt, moved);
        onReorder(next.map((e) => e.id).toList());
      },
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Padding(
          key: ValueKey(exercise.id),
          padding: EdgeInsets.only(bottom: index == exercises.length - 1 ? 0 : 6),
          child: _ExerciseCard(
            index: index,
            exercise: exercise,
            onDelete: () => onDelete(exercise),
            onToggleComplete: (completed) =>
                onToggleComplete(exercise, completed),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 35 * index),
                duration: 260.ms,
              )
              .slideY(begin: 0.03, end: 0),
        );
      },
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.onDelete,
    required this.onToggleComplete,
  });

  final int index;
  final GymExercise exercise;
  final VoidCallback onDelete;
  final void Function(bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.jm().format(exercise.timestamp);
    final done = exercise.isCompletedToday;
    final exerciseId = exercise.exerciseId;

    return Dismissible(
      key: ValueKey('dismiss-${exercise.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: done ? 0.55 : 1,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: exerciseId == null || exerciseId.isEmpty
                ? null
                : () => context.push('/workouts/exercise/$exerciseId'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done
                      ? AppColors.win.withValues(alpha: 0.35)
                      : AppColors.surfaceElevated,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    _ExerciseThumbnail(
                      imageUrl: exercise.imageUrl,
                      exerciseId: exercise.exerciseId,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: done
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                          ),
                          if (exercise.weightOrSetting.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise.weightOrSetting,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                          if (exercise.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.75),
                                    height: 1.3,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onToggleComplete(!done),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.win.withValues(alpha: 0.16)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: done
                                    ? AppColors.win.withValues(alpha: 0.55)
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(
                              done
                                  ? Icons.check_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: done
                                  ? AppColors.win
                                  : AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
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
    );
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({this.imageUrl, this.exerciseId});

  final String? imageUrl;
  final String? exerciseId;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    return ExerciseDemoStage(
      imageUrl: imageUrl,
      exerciseId: exerciseId,
      width: size,
      height: size,
      borderRadius: 10,
      fit: BoxFit.contain,
    );
  }
}
