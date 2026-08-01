import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Neon-green pulsating dot for live gym sessions.
class ActivePulseDot extends StatefulWidget {
  const ActivePulseDot({super.key, this.size = 12});

  final double size;

  @override
  State<ActivePulseDot> createState() => _ActivePulseDotState();
}

class _ActivePulseDotState extends State<ActivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.45 + (_controller.value * 0.55);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.win.withValues(alpha: pulse),
            border: Border.all(color: AppColors.win, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.win.withValues(alpha: 0.55 * pulse),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
