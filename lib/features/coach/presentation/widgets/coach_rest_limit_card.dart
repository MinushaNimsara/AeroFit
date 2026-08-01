import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoachRestLimitCard extends ConsumerStatefulWidget {
  const CoachRestLimitCard({super.key});

  @override
  ConsumerState<CoachRestLimitCard> createState() => _CoachRestLimitCardState();
}

class _CoachRestLimitCardState extends ConsumerState<CoachRestLimitCard> {
  double _restLimit = 3;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final restAsync = ref.watch(coachMaxRestMinutesProvider);

    restAsync.whenData((minutes) {
      if (!_initialized) {
        _restLimit = minutes.toDouble();
        _initialized = true;
      }
    });

    return Card(
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gym Rest Timer Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum Allowed Rest Limit (Minutes)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_restLimit.round()} min',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _restLimit,
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: '${_restLimit.round()} min',
                    onChanged: _isSaving
                        ? null
                        : (v) => setState(() => _restLimit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        await ref
                            .read(liveWorkoutControllerProvider)
                            .updateCoachRestLimit(_restLimit.round());
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rest limit saved: ${_restLimit.round()} minutes for all gym trainees.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.win,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not save rest limit: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Text('Save Rest Limit'),
            ),
          ],
        ),
      ),
    );
  }
}
