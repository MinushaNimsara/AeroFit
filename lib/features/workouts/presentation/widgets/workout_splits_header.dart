import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Workout splits',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateSplitDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create New Split'),
                  ),
                ],
              ),
              if (splits.isEmpty)
                _EmptySplitsHint(onCreate: () => _showCreateSplitDialog(context))
              else ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final split in splits)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(split.name),
                            selected: selectedId == split.id,
                            onSelected: (_) {
                              ref.read(selectedSplitIdProvider.notifier).state =
                                  split.id;
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.25),
                            backgroundColor: AppColors.surfaceElevated,
                            labelStyle: TextStyle(
                              color: selectedId == split.id
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: selectedId == split.id
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: selectedId == split.id
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : const Color(0xFF252B38),
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
}

class _EmptySplitsHint extends StatelessWidget {
  const _EmptySplitsHint({required this.onCreate});

  final VoidCallback onCreate;

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
            'Create your first split to start tracking exercises.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onCreate,
            child: const Text('+ Create New Split'),
          ),
        ],
      ),
    );
  }
}
