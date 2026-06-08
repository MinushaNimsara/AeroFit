import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:flutter/material.dart';

class StatusPillRow extends StatelessWidget {
  const StatusPillRow({super.key, required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Pill(
            label: 'Routine',
            done: status.routineComplete,
            subtitle: status.routineComplete ? 'Done' : 'Pending',
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Diet',
            done: status.dietCloseToTarget,
            subtitle:
                '${status.caloriesConsumed} / ${status.calorieGoal} kcal',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Gym',
            done: status.workoutComplete,
            subtitle: status.gymPillSubtitle,
            icon: Icons.fitness_center_rounded,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.done,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final bool done;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.win : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.win.withValues(alpha: 0.4)
              : const Color(0xFF252B38),
        ),
      ),
      child: Column(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: done ? AppColors.win : AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
