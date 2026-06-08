import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DailyWinLossBanner extends StatelessWidget {
  const DailyWinLossBanner({super.key, required this.isWin});

  final bool isWin;

  @override
  Widget build(BuildContext context) {
    final color = isWin ? AppColors.win : AppColors.loss;
    final icon = isWin ? Icons.emoji_events_rounded : Icons.trending_down_rounded;
    final title = isWin ? 'Daily Win' : 'Daily Loss';
    final subtitle = isWin
        ? 'Routine, diet target, and workout all complete.'
        : 'Keep going — complete routine, 2000 kcal target, and gym.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
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
