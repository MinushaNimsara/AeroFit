import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.color = AppColors.primary,
    this.lineWidth,
    this.center,
    this.showCaption = true,
  });

  final double progress;
  final double size;
  final Color color;
  final double? lineWidth;
  final Widget? center;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final percent = clamped * 100;

    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: lineWidth ?? size * 0.09,
      percent: clamped,
      animation: true,
      animationDuration: 1200,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: AppColors.ringTrack,
      progressColor: color,
      center: center ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percent.round()}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (showCaption) ...[
                const SizedBox(height: 2),
                Text(
                  'Daily goals',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
    );
  }
}
