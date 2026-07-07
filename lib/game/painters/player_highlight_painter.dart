import 'package:flutter/material.dart';

class PlayerHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width / 2, 4)
      ..lineTo(size.width - 4, size.height / 2)
      ..lineTo(size.width / 2, size.height - 4)
      ..lineTo(4, size.height / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}