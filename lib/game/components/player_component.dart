import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  int gridX;
  int gridY;

  PlayerComponent({required this.gridX, required this.gridY});

  void setGridPosition(int gx, int gy) {
    gridX = gx;
    gridY = gy;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final paint = Paint()
      ..color = Colors.yellow.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(w / 2, 4)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h - 4)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, paint);
  }
}