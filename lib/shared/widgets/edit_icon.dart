import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector pencil/edit icon — does not rely on Material Icons font (fixes blank PWA icons).
class EditIcon extends StatelessWidget {
  const EditIcon({
    super.key,
    required this.color,
    this.size = 20,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _EditIconPainter(color: color),
    );
  }
}

class _EditIconPainter extends CustomPainter {
  _EditIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.52);
    canvas.rotate(-math.pi / 4);

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.06),
        width: w * 0.38,
        height: h * 0.62,
      ),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(body, bodyPaint);

    final tip = Path()
      ..moveTo(-w * 0.19, h * 0.22)
      ..lineTo(w * 0.19, h * 0.22)
      ..lineTo(0, h * 0.42)
      ..close();
    canvas.drawPath(tip, bodyPaint..color = color.withValues(alpha: 0.72));

    final eraserPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -h * 0.34),
          width: w * 0.38,
          height: h * 0.14,
        ),
        Radius.circular(w * 0.04),
      ),
      eraserPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EditIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
