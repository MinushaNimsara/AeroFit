import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
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
    final splitsAsync = ref.watch(workoutSplitsStreamProvider);
    final exercisesAsync = ref.watch(splitExercisesStreamProvider);
    final selectedSplitId = ref.watch(effectiveSelectedSplitIdProvider);
    final progress = ref.watch(activeSplitGymProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        actions: [
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WorkoutSplitsHeader(),
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

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
    required this.onToggleComplete,
  });

  final GymExercise exercise;
  final VoidCallback onDelete;
  final void Function(bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(exercise.timestamp);
    final done = exercise.isCompletedToday;

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
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                _ExerciseThumbnail(imageUrl: exercise.imageUrl),
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
    );
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
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
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    }

    return _placeholder(size);
  }

  Widget _placeholder(double size) {
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
