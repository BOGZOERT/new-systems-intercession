import 'package:flutter/material.dart';

class IsoLeftPainter extends CustomPainter {
  final Color color;
  IsoLeftPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2, size.height * 1.5)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    paint
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}