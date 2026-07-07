import 'package:flutter/material.dart';
import 'tile_type.dart';
import 'building_type.dart';

class GameTile {
  final int x;
  final int y;
  TileType type;
  BuildingType building;

  GameTile({
    required this.x,
    required this.y,
    required this.type,
    this.building = BuildingType.none,
  });

  bool get isBuildable =>
      type == TileType.field || type == TileType.grass || type == TileType.plain;
  bool get hasBuilding => building != BuildingType.none;

  Color get topColor => hasBuilding ? _buildingTopColor(building) : _tileTopColor(type);
  Color get leftColor => hasBuilding ? _buildingLeftColor(building) : _tileLeftColor(type);
  Color get rightColor => hasBuilding ? _buildingRightColor(building) : _tileRightColor(type);

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

  static Color _tileLeftColor(TileType t) {
    switch (t) {
      case TileType.grass: return const Color(0xFF66BB6A);
      case TileType.forest: return const Color(0xFF1B5E20);
      case TileType.mountain: return const Color(0xFF757575);
      case TileType.river: return const Color(0xFF1E88E5);
      case TileType.field: return const Color(0xFFFFEE58);
      case TileType.plain: return const Color(0xFF81C784);
    }
  }

  static Color _tileRightColor(TileType t) {
    switch (t) {
      case TileType.grass: return const Color(0xFF4CAF50);
      case TileType.forest: return const Color(0xFF388E3C);
      case TileType.mountain: return const Color(0xFF616161);
      case TileType.river: return const Color(0xFF1976D2);
      case TileType.field: return const Color(0xFFFDD835);
      case TileType.plain: return const Color(0xFF66BB6A);
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

  static Color _buildingLeftColor(BuildingType b) {
    switch (b) {
      case BuildingType.house: return const Color(0xFFE53935);
      case BuildingType.sawmill: return const Color(0xFFFF9800);
      case BuildingType.storage: return const Color(0xFFFFC107);
      case BuildingType.castle: return const Color(0xFF8E24AA);
      default: return Colors.grey;
    }
  }

  static Color _buildingRightColor(BuildingType b) {
    switch (b) {
      case BuildingType.house: return const Color(0xFFC62828);
      case BuildingType.sawmill: return const Color(0xFFF57C00);
      case BuildingType.storage: return const Color(0xFFFFB300);
      case BuildingType.castle: return const Color(0xFF7B1FA2);
      default: return Colors.grey;
    }
  }
}