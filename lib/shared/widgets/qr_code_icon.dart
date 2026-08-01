import 'package:flutter/material.dart';

/// Vector QR icon — does not rely on Material Icons font (fixes blank PWA icons).
class QrCodeIcon extends StatelessWidget {
  const QrCodeIcon({
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
      painter: _QrCodeIconPainter(
        color: color,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
    );
  }
}

class _QrCodeIconPainter extends CustomPainter {
  _QrCodeIconPainter({
    required this.color,
    required this.backgroundColor,
  });

  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cut = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final unit = size.width / 10;

    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, unit * 3, unit * 3), fill);
      canvas.drawRect(
        Rect.fromLTWH(x + unit * 0.55, y + unit * 0.55, unit * 1.9, unit * 1.9),
        cut,
      );
      canvas.drawRect(Rect.fromLTWH(x + unit, y + unit, unit, unit), fill);
    }

    void drawModule(double x, double y) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, unit * 0.85, unit * 0.85),
        fill,
      );
    }

    drawFinder(0, 0);
    drawFinder(size.width - unit * 3, 0);
    drawFinder(0, size.width - unit * 3);

    drawModule(unit * 4, 0);
    drawModule(unit * 5.2, 0);
    drawModule(unit * 4, unit * 1.2);
    drawModule(unit * 6.4, unit * 1.2);
    drawModule(unit * 4, unit * 2.4);
    drawModule(unit * 5.2, unit * 2.4);

    drawModule(0, unit * 4);
    drawModule(unit * 1.2, unit * 4);
    drawModule(unit * 2.4, unit * 5.2);
    drawModule(0, unit * 5.2);
    drawModule(unit * 1.2, unit * 6.4);

    drawModule(unit * 4, unit * 4);
    drawModule(unit * 5.2, unit * 4);
    drawModule(unit * 6.4, unit * 5.2);
    drawModule(unit * 4, unit * 5.2);
    drawModule(unit * 5.2, unit * 6.4);
    drawModule(unit * 6.4, unit * 6.4);

    drawModule(unit * 4, unit * 7.6);
    drawModule(unit * 5.2, unit * 8.8);
    drawModule(unit * 6.4, unit * 7.6);
    drawModule(unit * 7.6, unit * 4);
    drawModule(unit * 8.8, unit * 5.2);
    drawModule(unit * 7.6, unit * 6.4);
  }

  @override
  bool shouldRepaint(covariant _QrCodeIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
