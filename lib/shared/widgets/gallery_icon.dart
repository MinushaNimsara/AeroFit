import 'package:flutter/material.dart';

/// Vector gallery/photo-stack icon — does not rely on Material Icons font
/// (avoids blank glyphs after Flutter web icon tree-shaking).
class GalleryIcon extends StatelessWidget {
  const GalleryIcon({
    super.key,
    required this.color,
    this.size = 28,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GalleryIconPainter(color: color),
    );
  }
}

class _GalleryIconPainter extends CustomPainter {
  _GalleryIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeJoin = StrokeJoin.round;

    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.68,
        size.height * 0.58,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(back, paint);

    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.28,
        size.width * 0.72,
        size.height * 0.60,
      ),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(front, paint);

    final mountain = Path()
      ..moveTo(size.width * 0.18, size.height * 0.72)
      ..lineTo(size.width * 0.36, size.height * 0.52)
      ..lineTo(size.width * 0.48, size.height * 0.64)
      ..lineTo(size.width * 0.62, size.height * 0.46)
      ..lineTo(size.width * 0.78, size.height * 0.72);
    canvas.drawPath(mountain, paint);

    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.44),
      size.width * 0.05,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GalleryIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
