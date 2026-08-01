import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RegistryShimmer extends StatefulWidget {
  const RegistryShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  State<RegistryShimmer> createState() => _RegistryShimmerState();
}

class _RegistryShimmerState extends State<RegistryShimmer>
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
      builder: (context, _) {
        return Column(
          children: List.generate(widget.rowCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerRow(progress: _controller.value),
            );
          }),
        );
      },
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Row(
        children: [
          _ShimmerBox(progress: progress, width: 40, height: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(progress: progress, height: 14, width: 160),
                const SizedBox(height: 8),
                _ShimmerBox(progress: progress, height: 12, width: 220),
                const SizedBox(height: 8),
                _ShimmerBox(progress: progress, height: 10, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.progress,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double progress;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final slide = (progress * 2) - 1;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + slide, 0),
          end: Alignment(1 + slide, 0),
          colors: const [
            Color(0xFF1A2030),
            Color(0xFF2A3142),
            Color(0xFF1A2030),
          ],
        ),
      ),
    );
  }
}
