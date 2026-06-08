import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.progress,
    this.size = 200,
  });

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final percent = clamped * 100;

    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: 14,
      percent: clamped,
      animation: true,
      animationDuration: 1200,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: AppColors.ringTrack,
      progressColor: AppColors.primary,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${percent.round()}%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily goals',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
