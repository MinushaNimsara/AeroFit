import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector gear icon — does not rely on Material Icons font (fixes blank PWA buttons).
class GearIcon extends StatelessWidget {
  const GearIcon({
    super.key,
    required this.color,
    this.size = 26,
    this.holeColor,
  });

  final Color color;
  final double size;
  final Color? holeColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GearIconPainter(
        color: color,
        holeColor: holeColor,
      ),
    );
  }
}

class _GearIconPainter extends CustomPainter {
  _GearIconPainter({
    required this.color,
    this.holeColor,
  });

  final Color color;
  final Color? holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.46;
    final innerR = size.width * 0.30;
    const teeth = 8;

    final gearPath = Path();
    for (var i = 0; i < teeth; i++) {
      final base = -math.pi / 2 + i * 2 * math.pi / teeth;
      final points = [
        Offset(
          center.dx + outerR * math.cos(base),
          center.dy + outerR * math.sin(base),
        ),
        Offset(
          center.dx + innerR * math.cos(base + math.pi / teeth * 0.5),
          center.dy + innerR * math.sin(base + math.pi / teeth * 0.5),
        ),
        Offset(
          center.dx + innerR * math.cos(base + math.pi / teeth),
          center.dy + innerR * math.sin(base + math.pi / teeth),
        ),
        Offset(
          center.dx + outerR * math.cos(base + math.pi / teeth * 1.5),
          center.dy + outerR * math.sin(base + math.pi / teeth * 1.5),
        ),
      ];

      if (i == 0) {
        gearPath.moveTo(points[0].dx, points[0].dy);
      } else {
        gearPath.lineTo(points[0].dx, points[0].dy);
      }
      gearPath.lineTo(points[1].dx, points[1].dy);
      gearPath.lineTo(points[2].dx, points[2].dy);
      gearPath.lineTo(points[3].dx, points[3].dy);
    }
    gearPath.close();

    canvas.drawPath(
      gearPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      size.width * 0.13,
      Paint()
        ..color = holeColor ?? const Color(0xFF1E2430)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GearIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.holeColor != holeColor;
  }
}
