import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showSetTraineeCaloriesDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String traineeUid,
  required String traineeName,
  required int currentGoal,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _SetTraineeCaloriesDialog(
      traineeUid: traineeUid,
      traineeName: traineeName,
      currentGoal: currentGoal,
    ),
  );
}

class _SetTraineeCaloriesDialog extends ConsumerStatefulWidget {
  const _SetTraineeCaloriesDialog({
    required this.traineeUid,
    required this.traineeName,
    required this.currentGoal,
  });

  final String traineeUid;
  final String traineeName;
  final int currentGoal;

  @override
  ConsumerState<_SetTraineeCaloriesDialog> createState() =>
      _SetTraineeCaloriesDialogState();
}

class _SetTraineeCaloriesDialogState
    extends ConsumerState<_SetTraineeCaloriesDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentGoal}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);
    try {
      final value = int.parse(_controller.text.trim());
      await ref.read(coachTraineeControllerProvider).updateTraineeCalorieGoal(
            traineeUid: widget.traineeUid,
            calorieGoal: value,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target calories set to $value for ${widget.traineeName}'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Set Target Calories for ${widget.traineeName}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Daily calorie target',
            suffixText: 'kcal',
          ),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            if (parsed == null || parsed < 500 || parsed > 10000) {
              return 'Enter a value between 500 and 10,000';
            }
            return null;
          },
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
