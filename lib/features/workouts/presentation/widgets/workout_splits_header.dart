import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:aerofit/features/workouts/presentation/widgets/build_my_routine_dialog.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutSplitsHeader extends ConsumerStatefulWidget {
  const WorkoutSplitsHeader({super.key});

  @override
  ConsumerState<WorkoutSplitsHeader> createState() =>
      _WorkoutSplitsHeaderState();
}

class _WorkoutSplitsHeaderState extends ConsumerState<WorkoutSplitsHeader> {
  @override
  Widget build(BuildContext context) {
    final splitsAsync = ref.watch(workoutSplitsStreamProvider);
    final selectedId = ref.watch(effectiveSelectedSplitIdProvider);

    return splitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Could not load splits: $e'),
      ),
      data: (splits) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Workout splits',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => showBuildMyRoutineDialog(context),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Build My Routine'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showCreateSplitDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Split'),
                  ),
                ],
              ),
              if (splits.isEmpty)
                _EmptySplitsHint(
                  onCreate: () => _showCreateSplitDialog(context),
                  onBuildRoutine: () => showBuildMyRoutineDialog(context),
                )
              else ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final split in splits)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SplitChip(
                            split: split,
                            selected: selectedId == split.id,
                            onSelect: () {
                              ref.read(selectedSplitIdProvider.notifier).state =
                                  split.id;
                            },
                            onDelete: () => _confirmDeleteSplit(context, split),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateSplitDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create workout split'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Chest & Back, Leg Day',
            labelText: 'Split name',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || !mounted) return;

    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(workoutSplitsRepositoryProvider);
    if (uid == null || repo == null) return;

    try {
      final id = await repo.createSplit(uid: uid, name: name);
      ref.read(selectedSplitIdProvider.notifier).state = id;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create split: $e')),
      );
    }
  }

  Future<void> _confirmDeleteSplit(
    BuildContext context,
    WorkoutSplit split,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete split?'),
        content: Text(
          'This removes "${split.name}" and every exercise in it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final uid = ref.read(authStateProvider).value?.uid;
    final splitsRepo = ref.read(workoutSplitsRepositoryProvider);
    final exercisesRepo = ref.read(exercisesRepositoryProvider);
    if (uid == null || splitsRepo == null || exercisesRepo == null) return;

    try {
      await exercisesRepo.deleteExercisesForSplit(uid: uid, splitId: split.id);
      await splitsRepo.deleteSplit(uid: uid, splitId: split.id);

      if (ref.read(selectedSplitIdProvider) == split.id) {
        ref.read(selectedSplitIdProvider.notifier).state = null;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${split.name}".')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete split: $e')),
      );
    }
  }
}

class _SplitChip extends StatelessWidget {
  const _SplitChip({
    required this.split,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final WorkoutSplit split;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.25)
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 6),
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : const Color(0xFF252B38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                split.name,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySplitsHint extends StatelessWidget {
  const _EmptySplitsHint({required this.onCreate, required this.onBuildRoutine});

  final VoidCallback onCreate;
  final VoidCallback onBuildRoutine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            'Build your own routine from the exercise library, or start with an empty split.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onBuildRoutine,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Build My Routine'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCreate,
            child: const Text('Or create an empty split'),
          ),
        ],
      ),
    );
  }
}
