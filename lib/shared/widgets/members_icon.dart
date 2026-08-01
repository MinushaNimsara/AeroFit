import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector members icon — does not rely on Material Icons font (fixes blank PWA icons).
class MembersIcon extends StatelessWidget {
  const MembersIcon({
    super.key,
    required this.color,
    this.size = 22,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MembersIconPainter(color: color),
    );
  }
}

class _MembersIconPainter extends CustomPainter {
  _MembersIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    void drawPerson({required double headX, required double scale}) {
      final headR = w * 0.14 * scale;
      canvas.drawCircle(Offset(headX, h * 0.34), headR, paint);

      final body = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(headX, h * 0.72),
            width: w * 0.42 * scale,
            height: h * 0.38 * scale,
          ),
          math.pi,
          math.pi,
        );
      canvas.drawPath(body, paint);
    }

    drawPerson(headX: w * 0.34, scale: 0.92);
    drawPerson(headX: w * 0.66, scale: 1);
  }

  @override
  bool shouldRepaint(covariant _MembersIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
