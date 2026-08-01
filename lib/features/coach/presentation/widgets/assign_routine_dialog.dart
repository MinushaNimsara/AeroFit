import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAssignRoutineDialog(
  BuildContext context, {
  required String traineeUid,
  required String traineeName,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AssignRoutineDialog(
      traineeUid: traineeUid,
      traineeName: traineeName,
    ),
  );
}

class AssignRoutineDialog extends ConsumerStatefulWidget {
  const AssignRoutineDialog({
    super.key,
    required this.traineeUid,
    required this.traineeName,
  });

  final String traineeUid;
  final String traineeName;

  @override
  ConsumerState<AssignRoutineDialog> createState() =>
      _AssignRoutineDialogState();
}

class _AssignRoutineDialogState extends ConsumerState<AssignRoutineDialog> {
  String? _selectedTemplateId;
  bool _assigning = false;

  Future<void> _confirmAssignment() async {
    final templateId = _selectedTemplateId;
    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a routine template first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _assigning = true);
    try {
      final routineName = await ref
          .read(coachRoutineControllerProvider)
          .assignRoutineToTrainee(
            traineeUid: widget.traineeUid,
            templateId: templateId,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.win),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Successfully assigned $routineName to ${widget.traineeName}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.win.withValues(alpha: 0.5)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(coachWorkoutTemplatesProvider);
    final templates = templatesAsync.valueOrNull ?? const [];

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      title: Row(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Assign Routine to ${widget.traineeName}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: templatesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text(
            'Could not load routines: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (_) {
            if (templates.isEmpty) {
              return Text(
                'No workout routines yet. Create one from the Routine Builder below your roster.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a template to copy into this trainee\'s active gym schedule.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF252B38)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedTemplateId,
                      hint: const Text('Select routine template'),
                      dropdownColor: AppColors.surfaceElevated,
                      items: templates
                          .map(
                            (template) => DropdownMenuItem(
                              value: template.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${template.totalDays} day(s) · ${template.exercisePreview.take(3).join(', ')}${template.exercisePreview.length > 3 ? '…' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _assigning
                          ? null
                          : (value) => setState(() => _selectedTemplateId = value),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _assigning ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _assigning || templates.isEmpty
              ? null
              : () => _confirmAssignment(),
          icon: _assigning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_assigning ? 'Assigning…' : 'Confirm Assignment'),
        ),
      ],
    );
  }
}
