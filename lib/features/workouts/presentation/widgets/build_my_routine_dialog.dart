import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_picker_sheet.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _SelectedExercise {
  const _SelectedExercise({required this.name, this.exerciseId});

  final String name;
  final String? exerciseId;
}

/// Lets a trainee build their own multi-exercise workout day in one flow —
/// picking from the 729-exercise library (or adding custom entries) — as an
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
      setState(() => _exercisesError = 'Not signed in or Firebase unavailable.');
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
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Build My Routine'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your own workout day using the exercise library — separate from anything your coach has assigned.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
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
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                if (_selected.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF252B38)),
                    ),
                    child: Text(
                      'No exercises added yet. Pick from the 729-exercise library or add a custom one.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  )
                else
                  ...List.generate(_selected.length, (index) {
                    final entry = _selected[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF252B38)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.exerciseId != null
                                ? Icons.menu_book_rounded
                                : Icons.edit_note_rounded,
                            size: 18,
                            color: entry.exerciseId != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _saving ? null : () => _removeAt(index),
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
                  }),
                if (_exercisesError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _exercisesError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _addFromLibrary,
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('From Library'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _addCustom,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Custom'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Routine'),
        ),
      ],
    );
  }
}

Future<void> showBuildMyRoutineDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const BuildMyRoutineDialog(),
  );
}
