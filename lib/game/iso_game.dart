import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/tile_component.dart';
import 'components/player_component.dart';
import 'models/tile_type.dart';
import 'models/building_type.dart';
import 'data/building_costs.dart';

class IsoGame extends FlameGame with MultiTouchTapDetector {
  final int gridSize;
  final Function(int wood, int stone, int food, int turns, int population, String status) onUpdate;
  final Function(String message) onLog;
  final Function() onGameEnd;

  late List<List<TileComponent>> _grid;
  late PlayerComponent _player;
  int _wood = 0;
  int _stone = 0;
  int _food = 10;
  int _turns = 50;
  int _population = 5;
  int _houses = 0;

  IsoGame({
    this.gridSize = 15,
    required this.onUpdate,
    required this.onLog,
    required this.onGameEnd,
  });

  int get turns => _turns;
  int get wood => _wood;
  int get stone => _stone;
  int get food => _food;
  int get population => _population;

  // Бонус к добыче от населения (каждые 5 человек = +1)
  int get _gatherBonus => _population ~/ 5;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    _generateMap();

    Future.microtask(() {
      _updateUI('Постройте поселение!');
      onLog('🏰 День 1. Постройте поселение! (👥 $_population чел.)');
    });
  }

  String _tileName(TileType type) {
    switch (type) {
      case TileType.forest: return 'Лес 🌲';
      case TileType.mountain: return 'Горы ⛰️';
      case TileType.river: return 'Река 💧';
      case TileType.field: return 'Поле 🌾';
      case TileType.grass: return 'Трава 🌿';
      case TileType.plain: return 'Равнина 🟫';
    }
  }

  void _generateBackground() {
    final bgSize = Vector2(320, 160);
    final tileSize = Vector2(80, 40);
    final center = gridSize ~/ 2;

    final mapCenter = Vector2(
      (center - center) * tileSize.x / 2 + 600,
      (center + center) * tileSize.y / 2 + 200,
    );

    final cols = 20;
    final rows = 20;

    for (int x = -cols ~/ 2; x < cols ~/ 2; x++) {
      for (int y = -rows ~/ 2; y < rows ~/ 2; y++) {
        final bgTile = _BackgroundTile(
          position: Vector2(
              (x - y) * bgSize.x / 2 + mapCenter.x,
              (x + y) * bgSize.y / 2 + mapCenter.y),
          size: bgSize,
        )..priority = -1;
        add(bgTile);
      }
    }
  }

  void _generateMap() {
    removeAll(children);

    _generateBackground();

    final random = Random();
    final tileSize = Vector2(80, 40);
    final center = gridSize ~/ 2;

    final offsetX = 600.0;
    final offsetY = 200.0;

    _grid = List.generate(gridSize, (x) {
      return List.generate(gridSize, (y) {
        final r = random.nextDouble();
        TileType type;
        if (r < 0.10) {
          type = TileType.river;
        } else if (r < 0.20) {
          type = TileType.mountain;
        } else if (r < 0.40) {
          type = TileType.forest;
        } else if (r < 0.48) {
          type = TileType.field;
        } else if (r < 0.56) {
          type = TileType.plain;
        } else {
          type = TileType.grass;
        }

        final tile = TileComponent(gridX: x, gridY: y, type: type)
          ..size = tileSize
          ..position = Vector2(
              (x - y) * tileSize.x / 2 + offsetX,
              (x + y) * tileSize.y / 2 + offsetY);
        return tile;
      });
    });

    _grid[center][center].type = TileType.grass;
    _grid[center][center].building = BuildingType.house;
    _houses = 1;
    _population = 5;

    for (int sum = 0; sum <= (gridSize - 1) * 2; sum++) {
      for (int x = 0; x < gridSize; x++) {
        final y = sum - x;
        if (y >= 0 && y < gridSize) {
          add(_grid[x][y]);
        }
      }
    }

    _player = PlayerComponent(gridX: center, gridY: center)
      ..size = tileSize
      ..position = _grid[center][center].position;
    add(_player);
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    final pos = info.eventPosition.widget;

    for (int sum = (gridSize - 1) * 2; sum >= 0; sum--) {
      for (int x = gridSize - 1; x >= 0; x--) {
        final y = sum - x;
        if (y >= 0 && y < gridSize) {
          final tile = _grid[x][y];
          final localPos = pos - tile.position;
          if (_isPointInIsoTile(localPos, tile.size)) {
            _onTileTap(x, y);
            return;
          }
        }
      }
    }
  }

  bool _isPointInIsoTile(Vector2 point, Vector2 size) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final dx = (point.x - cx).abs() / cx;
    final dy = (point.y - cy).abs() / cy;
    return dx + dy <= 1.0;
  }

  void _onTileTap(int gx, int gy) {
    if (_turns <= 0) return;
    final dx = gx.compareTo(_player.gridX);
    final dy = gy.compareTo(_player.gridY);
    if (dx != 0) {
      movePlayer(dx, 0);
    } else if (dy != 0) {
      movePlayer(0, dy);
    }
  }

  void movePlayer(int dx, int dy) {
    if (_turns <= 0) return;
    final newX = _player.gridX + dx;
    final newY = _player.gridY + dy;
    if (newX < 0 || newX >= gridSize || newY < 0 || newY >= gridSize) return;

    _player.setGridPosition(newX, newY);
    _player.position = _grid[newX][newY].position;
    _turns--;
    _collectResources();
    final tile = _grid[newX][newY];
    _updateUI('${_tileName(tile.type)}');
    _checkEnd();
  }

  void _collectResources() {
    final tile = _grid[_player.gridX][_player.gridY];
    int bonus = _gatherBonus;

    switch (tile.type) {
      case TileType.forest:
        final gained = 2 + bonus;
        _food += gained;
        onLog('🌲 Лес: +$gained еды (👥 бонус +$bonus)');
        break;
      case TileType.river:
        final gained = 1 + bonus;
        _food += gained;
        onLog('💧 Река: +$gained еды (👥 бонус +$bonus)');
        break;
      case TileType.field:
        final gained = 1 + bonus;
        _food += gained;
        onLog('🌾 Поле: +$gained еды (👥 бонус +$bonus)');
        break;
      case TileType.mountain:
        final gained = 1 + bonus;
        _stone += gained;
        onLog('⛰️ Горы: +$gained камня (👥 бонус +$bonus)');
        break;
      case TileType.grass:
        final gained = 1 + bonus;
        _stone += gained;
        onLog('🌿 Трава: +$gained камня (👥 бонус +$bonus)');
        break;
      default:
        break;
    }

    // Бонус от лесопилки
    if (tile.hasBuilding && tile.building == BuildingType.sawmill) {
      final woodGain = 2 + bonus;
      _wood += woodGain;
      onLog('🪚 Лесопилка: +$woodGain дерева (👥 бонус +$bonus)');
    }

    // Бонус от хранилища: +1 ко всем ресурсам
    if (tile.hasBuilding && tile.building == BuildingType.storage) {
      _wood += 1;
      _stone += 1;
      _food += 1;
      onLog('📦 Хранилище: +1 ко всем ресурсам');
    }
  }

  void chopWood() {
    if (_turns <= 0) return;
    final tile = _grid[_player.gridX][_player.gridY];
    if (tile.type == TileType.forest) {
      final gained = 2 + _gatherBonus;
      _wood += gained;
      _turns--;
      _updateUI('Добыто дерево: +$gained');
      onLog('🪓 Добыто дерево: +$gained (👥 бонус +$_gatherBonus)');
    } else {
      _updateUI('Здесь нет леса');
    }
    _checkEnd();
  }

  void mineStone() {
    if (_turns <= 0) return;
    final tile = _grid[_player.gridX][_player.gridY];
    if (tile.type == TileType.mountain) {
      final gained = 3 + _gatherBonus;
      _stone += gained;
      _turns--;
      _updateUI('Добыто камня: +$gained');
      onLog('⛏️ Добыто камня: +$gained (👥 бонус +$_gatherBonus)');
    } else {
      _updateUI('Здесь нет гор');
    }
    _checkEnd();
  }

  void build(BuildingType buildingType) {
    if (_turns <= 0) return;
    final tile = _grid[_player.gridX][_player.gridY];
    if (!tile.isBuildable) { _updateUI('Нельзя строить здесь'); return; }
    if (tile.hasBuilding) { _updateUI('Уже есть здание'); return; }

    final cost = buildingCosts[buildingType]!;
    if (_wood < cost['wood']! || _stone < cost['stone']! || _food < cost['food']!) {
      _updateUI('Недостаточно ресурсов');
      return;
    }

    _wood -= cost['wood']!;
    _stone -= cost['stone']!;
    _food -= cost['food']!;
    tile.building = buildingType;
    _turns--;

    // Бонусы от построек
    switch (buildingType) {
      case BuildingType.house:
        _houses++;
        _population += 2;
        _updateUI('Построен Дом 🏠 (👥 +2)');
        onLog('🔨 Дом 🏠: население +2 (👥 $_population)');
        break;
      case BuildingType.sawmill:
        _updateUI('Построена Лесопилка 🪚 (+2 дерева/ход)');
        onLog('🔨 Лесопилка 🪚: +2 дерева каждый ход');
        break;
      case BuildingType.storage:
        _updateUI('Построено Хранилище 📦 (+1 ко всем)');
        onLog('🔨 Хранилище 📦: +1 ко всем ресурсам на клетке');
        break;
      case BuildingType.castle:
        _turns += 50;
        _updateUI('Построен Замок 🏰 (+50 ходов!)');
        onLog('🔨 Замок 🏰: +50 ходов! 🎉');
        break;
      default:
        _updateUI('Построено: ${buildingName(buildingType)}');
        onLog('🔨 Построено: ${buildingName(buildingType)}');
    }

    _checkEnd();
  }

  void _updateUI(String status) {
    onUpdate(_wood, _stone, _food, _turns, _population, status);
  }

  void _checkEnd() {
    if (_turns <= 0) {
      Future.microtask(() => onGameEnd());
    }
  }

  int countBuildings() {
    int count = 0;
    for (var row in _grid) {
      for (var tile in row) {
        if (tile.hasBuilding) count++;
      }
    }
    return count;
  }
}

class _BackgroundTile extends PositionComponent {
  _BackgroundTile({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final w = size.x;
    final h = size.y;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, paint);
  }
}