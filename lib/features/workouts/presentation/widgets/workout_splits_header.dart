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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Splits',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              if (splits.isEmpty)
                _EmptySplitsHint(
                  onCreate: () => _showCreateSplitDialog(context),
                  onBuildRoutine: () => showBuildMyRoutineDialog(context),
                )
              else ...[
                const SizedBox(height: 10),
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
                      Material(
                        color: AppColors.surfaceElevated,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => _showCreateSplitDialog(context),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(Icons.add_rounded, size: 20),
                          ),
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
      color: selected ? AppColors.primary : AppColors.surfaceElevated,
      borderRadius: AppRadii.pillBr,
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadii.pillBr,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  split.name,
                  style: TextStyle(
                    color:
                        selected ? AppColors.background : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: selected
                          ? AppColors.background.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
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

class _EmptySplitsHint extends StatelessWidget {
  const _EmptySplitsHint(
      {required this.onCreate, required this.onBuildRoutine});

  final VoidCallback onCreate;
  final VoidCallback onBuildRoutine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardBr,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'No splits yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Build a routine from the library, or start with an empty split.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onBuildRoutine,
            child: const Text('Build My Routine'),
          ),
          TextButton(
            onPressed: onCreate,
            child: const Text('Create empty split'),
          ),
        ],
      ),
    );
  }
}
