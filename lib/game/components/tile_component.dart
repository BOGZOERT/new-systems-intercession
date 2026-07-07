import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/tile_type.dart';
import '../models/building_type.dart';

class TileComponent extends PositionComponent {
  final int gridX;
  final int gridY;
  TileType type;
  BuildingType building;

  TileComponent({
    required this.gridX,
    required this.gridY,
    required this.type,
    this.building = BuildingType.none,
  });

  bool get isBuildable =>
      type == TileType.field || type == TileType.grass || type == TileType.plain;
  bool get hasBuilding => building != BuildingType.none;

  Color get topColor => hasBuilding ? _buildingTopColor(building) : _tileTopColor(type);

  String get emoji {
    if (hasBuilding) {
      switch (building) {
        case BuildingType.house: return '🏠';
        case BuildingType.sawmill: return '🪚';
        case BuildingType.storage: return '📦';
        case BuildingType.castle: return '🏰';
        default: return '';
      }
    }
    switch (type) {
      case TileType.forest: return '🌲';
      case TileType.mountain: return '⛰️';
      case TileType.river: return '💧';
      case TileType.field: return '🌾';
      case TileType.grass: return '🌿';
      case TileType.plain: return '🟫';
    }
  }

  static Color _tileTopColor(TileType t) {
    switch (t) {
      case TileType.grass: return const Color(0xFF7BC67E);
      case TileType.forest: return const Color(0xFF2E7D32);
      case TileType.mountain: return const Color(0xFF9E9E9E);
      case TileType.river: return const Color(0xFF42A5F5);
      case TileType.field: return const Color(0xFFFFF176);
      case TileType.plain: return const Color(0xFFA5D6A7);
    }
  }

  static Color _buildingTopColor(BuildingType b) {
    switch (b) {
      case BuildingType.house: return const Color(0xFFEF5350);
      case BuildingType.sawmill: return const Color(0xFFFFA726);
      case BuildingType.storage: return const Color(0xFFFFD54F);
      case BuildingType.castle: return const Color(0xFFAB47BC);
      default: return Colors.grey;
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = topColor;
    final topPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(topPath, paint);

    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: w * 0.25, color: Colors.black)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w / 2 - textPainter.width / 2, h / 2 - textPainter.height / 2));
  }
}