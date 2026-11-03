import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/daily_goal_ring.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Overall daily progress ring with the win / loss verdict beside it.
class DailyWinLossBanner extends StatelessWidget {
  const DailyWinLossBanner({
    super.key,
    required this.isWin,
    required this.calorieGoal,
    required this.progress,
  });

  final bool isWin;
  final int calorieGoal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final color = isWin ? AppColors.win : AppColors.loss;
    final icon =
        isWin ? Icons.emoji_events_rounded : Icons.trending_down_rounded;
    final title = isWin ? 'Daily Win' : 'Daily Loss';
    final subtitle = isWin
        ? 'Routine, diet target, and workout all complete.'
        : 'Keep going — complete routine, $calorieGoal kcal target, and gym.';

    return AppCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.12),
          AppColors.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          DailyGoalRing(
            progress: progress,
            size: 104,
            lineWidth: 10,
            showCaption: false,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconChip(icon: icon, color: color, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress.clamp(0.0, 1.0) * 100).round()}% of daily goals',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
