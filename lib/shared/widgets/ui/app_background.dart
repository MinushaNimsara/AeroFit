import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Near-black canvas with two soft color glows near the top.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.intensity = 1});

  final Widget child;

  /// 0..1 multiplier for glow strength.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.1, -1.05),
                    radius: 1.1,
                    colors: [
                      AppColors.glowWarm.withValues(alpha: 0.55 * intensity),
                      AppColors.glowWarm.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.2, -0.55),
                    radius: 1.0,
                    colors: [
                      AppColors.glowCool.withValues(alpha: 0.45 * intensity),
                      AppColors.glowCool.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
