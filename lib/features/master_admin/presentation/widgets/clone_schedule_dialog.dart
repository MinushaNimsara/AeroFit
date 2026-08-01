import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/domain/coach_workout_schedule.dart';
import 'package:aerofit/features/master_admin/providers/gym_detail_providers.dart';
import 'package:aerofit/features/master_admin/providers/platform_analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showCloneScheduleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required CoachRegistryEntry sourceGym,
  required CoachWorkoutSchedule schedule,
}) async {
  final registry =
      ref.read(coachRegistryStreamProvider).valueOrNull ?? const [];
  final destinations = registry
      .where((gym) => gym.uid != sourceGym.uid)
      .toList();

  if (destinations.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No other gyms are available to copy this schedule to.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  CoachRegistryEntry? selected = destinations.first;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: const Text('Copy to Another Gym'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Duplicate "${schedule.name}" to another coach\'s gym.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CoachRegistryEntry>(
                    initialValue: selected,
                    decoration: const InputDecoration(
                      labelText: 'Destination gym',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    items: destinations
                        .map(
                          (gym) => DropdownMenuItem(
                            value: gym,
                            child: Text('${gym.gymName} — ${gym.coachName}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        final success = await ref
                            .read(scheduleCloneProvider.notifier)
                            .cloneSchedule(
                              sourceGym: sourceGym,
                              schedule: schedule,
                              targetGym: selected!,
                            );

                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();

                        final cloneState = ref.read(scheduleCloneProvider);
                        if (success && cloneState.message != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cloneState.message!),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.win,
                            ),
                          );
                        } else if (cloneState.message != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cloneState.message!),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                child: const Text('Copy Schedule'),
              ),
            ],
          );
        },
      );
    },
  );
}
