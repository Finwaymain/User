import 'package:flutter/material.dart';
import 'dart:math' as math;

class HexagonPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final hexSize = 30.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * math.sqrt(3))).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final xOffset = col * hexSize * math.sqrt(3) +
            (row.isOdd ? hexSize * math.sqrt(3) / 2 : 0);
        final yOffset = row * hexSize * 1.5;
        _drawHexagon(canvas, paint, Offset(xOffset, yOffset), hexSize);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}