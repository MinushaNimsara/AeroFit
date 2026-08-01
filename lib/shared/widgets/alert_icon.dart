import 'package:flutter/material.dart';

/// Vector alert icon — does not rely on Material Icons font (fixes blank PWA icons).
class AlertIcon extends StatelessWidget {
  const AlertIcon({
    super.key,
    required this.color,
    this.backgroundColor,
    this.size = 24,
  });

  final Color color;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AlertIconPainter(
        color: color,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
    );
  }
}

class _AlertIconPainter extends CustomPainter {
  _AlertIconPainter({
    required this.color,
    required this.backgroundColor,
  });

  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final triangle = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.92, h * 0.88)
      ..lineTo(w * 0.08, h * 0.88)
      ..close();
    canvas.drawPath(triangle, paint);

    final cut = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: w * 0.1,
          height: h * 0.28,
        ),
        const Radius.circular(1.5),
      ),
      cut,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.78), w * 0.06, cut);
  }

  @override
  bool shouldRepaint(covariant _AlertIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
