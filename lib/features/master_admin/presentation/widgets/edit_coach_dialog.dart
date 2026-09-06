import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEditCoachDialog(
  BuildContext context,
  WidgetRef ref,
  CoachRegistryEntry entry,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _EditCoachDialog(entry: entry),
  );
}

class _EditCoachDialog extends ConsumerStatefulWidget {
  const _EditCoachDialog({required this.entry});

  final CoachRegistryEntry entry;

  @override
  ConsumerState<_EditCoachDialog> createState() => _EditCoachDialogState();
}

class _EditCoachDialogState extends ConsumerState<_EditCoachDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _gymName;
  late final TextEditingController _coachName;

  @override
  void initState() {
    super.initState();
    _gymName = TextEditingController(text: widget.entry.gymName);
    _coachName = TextEditingController(text: widget.entry.coachName);
  }

  @override
  void dispose() {
    _gymName.dispose();
    _coachName.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    await ref.read(coachEditProvider.notifier).saveCoachProfile(
          coachUid: widget.entry.uid,
          gymName: _gymName.text,
          coachFullName: _coachName.text,
        );
  }

  Future<void> _triggerPasswordReset() async {
    await ref.read(coachEditProvider.notifier).triggerPasswordReset(
          coachEmail: widget.entry.email,
          coachName: widget.entry.coachName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(coachEditProvider);
    final isSaving = editState.isSavingProfile;
    final isSendingReset = editState.isSendingReset;
    final isBusy = isSaving || isSendingReset;

    ref.listen<CoachEditState>(coachEditProvider, (previous, next) {
      if (next.profileSaved) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Coach profile updated.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.win,
          ),
        );
        ref.read(coachEditProvider.notifier).reset();
      } else if (next.passwordResetSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.message ??
                  'Password reset email sent to ${widget.entry.email}.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.win,
          ),
        );
        ref.read(coachEditProvider.notifier).clearPasswordResetFlag();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(coachEditProvider.notifier).clearError();
      }
    });

    final canReset = widget.entry.email.trim().isNotEmpty &&
        widget.entry.email != '—';

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Edit Coach & Gym Profile'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.entry.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gymName,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Gym Name',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Gym name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coachName,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Coach Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Coach name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: !isBusy && canReset ? _triggerPasswordReset : null,
                icon: isSendingReset
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset_rounded),
                label: Text(
                  isSendingReset
                      ? 'Sending reset email…'
                      : 'Trigger Password Reset Email',
                ),
              ),
              if (!canReset) ...[
                const SizedBox(height: 8),
                Text(
                  'No email on file — password reset unavailable.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _saveProfile,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
