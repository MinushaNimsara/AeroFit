import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_category_visual.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
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
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (progress.$1 == progress.$2
                            ? AppColors.win
                            : AppColors.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (progress.$1 == progress.$2
                              ? AppColors.win
                              : AppColors.primary)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${progress.$1} / ${progress.$2} done',
                    style: TextStyle(
                      color: progress.$1 == progress.$2
                          ? AppColors.win
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
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
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GymMembershipBanner(),
                ),
              const WorkoutSplitsHeader(),
              _StartWorkoutBanner(
                exercisesAsync: exercisesAsync,
                splitsAsync: splitsAsync,
                selectedSplitId: selectedSplitId,
              ),
              const SizedBox(height: 8),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.surfaceElevated,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
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
            const SizedBox(height: 6),
            Text(
              inSession
                  ? 'Current: ${liveStatus?.activeExerciseLabel ?? splitName}'
                  : exerciseCount > 0
                      ? '$exerciseCount exercises lined up for $splitName'
                      : 'Pick $splitName and start your live gym session',
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
  });

  final List<GymExercise> exercises;
  final String? splitName;
  final void Function(GymExercise exercise) onDelete;
  final void Function(GymExercise exercise, bool completed) onToggleComplete;

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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ExerciseCard(
          exercise: exercises[index],
          onDelete: () => onDelete(exercises[index]),
          onToggleComplete: (completed) =>
              onToggleComplete(exercises[index], completed),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 45 * index), duration: 300.ms)
            .slideY(begin: 0.04, end: 0);
      },
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
    required this.onToggleComplete,
  });

  final GymExercise exercise;
  final VoidCallback onDelete;
  final void Function(bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.jm().format(exercise.timestamp);
    final done = exercise.isCompletedToday;
    final exerciseId = exercise.exerciseId;

    return Dismissible(
      key: ValueKey(exercise.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: done ? 0.65 : 1,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: exerciseId == null || exerciseId.isEmpty
              ? null
              : () => context.push('/workouts/exercise/$exerciseId'),
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? AppColors.win.withValues(alpha: 0.45)
                  : const Color(0xFF252B38),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseThumbnail(
                  imageUrl: exercise.imageUrl,
                  exerciseId: exercise.exerciseId,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              color: done
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                      ),
                    if (exercise.weightOrSetting.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exercise.weightOrSetting,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (exercise.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onToggleComplete(!done),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.win.withValues(alpha: 0.18)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: done
                              ? AppColors.win.withValues(alpha: 0.6)
                              : const Color(0xFF353D4D),
                        ),
                      ),
                      child: Icon(
                        done
                            ? Icons.check_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: done ? AppColors.win : AppColors.textSecondary,
                        size: 22,
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

class _ExerciseThumbnail extends ConsumerWidget {
  const _ExerciseThumbnail({this.imageUrl, this.exerciseId});

  final String? imageUrl;
  final String? exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const size = 72.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: AppColors.surfaceElevated,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _placeholder(context, ref, size),
        ),
      );
    }

    return _placeholder(context, ref, size);
  }

  Widget _placeholder(BuildContext context, WidgetRef ref, double size) {
    final id = exerciseId;
    if (id != null && id.isNotEmpty) {
      final exercise = ref.watch(exerciseByIdProvider(id)).valueOrNull;
      if (exercise != null) {
        return ExerciseCategoryIcon(category: exercise.category, size: size);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }
}
