import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_picker_sheet.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _SelectedExercise {
  const _SelectedExercise({required this.name, this.exerciseId});

  final String name;
  final String? exerciseId;
}

/// Lets a trainee build their own multi-exercise workout day in one flow —
/// picking from the exercise library (or adding custom entries) — as an
/// alternative to whatever schedule their coach has assigned. Saves as a
/// regular (non coach-assigned) workout split so it lives alongside any
/// coach routine rather than replacing it.
class BuildMyRoutineDialog extends ConsumerStatefulWidget {
  const BuildMyRoutineDialog({super.key});

  @override
  ConsumerState<BuildMyRoutineDialog> createState() =>
      _BuildMyRoutineDialogState();
}

class _BuildMyRoutineDialogState extends ConsumerState<BuildMyRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_SelectedExercise> _selected = [];
  bool _saving = false;
  String? _exercisesError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addFromLibrary() async {
    final picked = await showMultiExercisePickerSheet(context);
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() {
      final existingIds =
          _selected.map((e) => e.exerciseId).whereType<String>().toSet();
      for (final Exercise exercise in picked) {
        if (existingIds.contains(exercise.id)) continue;
        _selected.add(
          _SelectedExercise(name: exercise.name, exerciseId: exercise.id),
        );
      }
      _exercisesError = null;
    });
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Add custom exercise'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Exercise name',
            hintText: 'e.g. Incline Treadmill Walk',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() {
        _selected.add(_SelectedExercise(name: name.trim()));
        _exercisesError = null;
      });
    }
  }

  void _removeAt(int index) {
    setState(() => _selected.removeAt(index));
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selected.isEmpty) {
      setState(() => _exercisesError = 'Add at least one exercise');
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final splitsRepo = ref.read(workoutSplitsRepositoryProvider);
    final exercisesRepo = ref.read(exercisesRepositoryProvider);
    if (uid == null || splitsRepo == null || exercisesRepo == null) {
      setState(
          () => _exercisesError = 'Not signed in or Firebase unavailable.');
      return;
    }

    setState(() {
      _saving = true;
      _exercisesError = null;
    });

    try {
      final splitId = await splitsRepo.createSplit(
        uid: uid,
        name: _nameController.text,
      );

      for (final entry in _selected) {
        await exercisesRepo.addExercise(
          uid: uid,
          splitId: splitId,
          name: entry.name,
          weightOrSetting: '',
          notes: '',
          exerciseId: entry.exerciseId,
        );
      }

      ref.read(selectedSplitIdProvider.notifier).state = splitId;

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_nameController.text.trim()}" is ready to train.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exercisesError = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const IconChip(
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build routine',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your own workout day — separate from a coach plan',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Routine name',
                  hintText: 'e.g. My Push Day',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a routine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              if (_selected.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  color: AppColors.surfaceElevated,
                  child: Text(
                    'No exercises yet. Add from the library or a custom name.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < _selected.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _selected.length - 1 ? 0 : 8,
                            ),
                            child: _ExerciseChip(
                              entry: _selected[index],
                              onRemove: _saving ? null : () => _removeAt(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_exercisesError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _exercisesError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.menu_book_rounded,
                      label: 'From library',
                      onTap: _saving ? null : _addFromLibrary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.add_rounded,
                      label: 'Custom',
                      onTap: _saving ? null : _addCustom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Save routine'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({required this.entry, required this.onRemove});

  final _SelectedExercise entry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final fromLibrary = entry.exerciseId != null;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      color: AppColors.surfaceElevated,
      radius: AppRadii.chipBr,
      child: Row(
        children: [
          Icon(
            fromLibrary ? Icons.menu_book_rounded : Icons.edit_note_rounded,
            size: 18,
            color: fromLibrary ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppTile(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showBuildMyRoutineDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const BuildMyRoutineDialog(),
  );
}
