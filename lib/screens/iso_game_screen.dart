import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import '../game/iso_game.dart';
import '../game/models/building_type.dart';
import '../game/data/building_costs.dart';

class IsoGameScreen extends StatefulWidget {
  const IsoGameScreen({super.key});

  @override
  State<IsoGameScreen> createState() => _IsoGameScreenState();
}

class _IsoGameScreenState extends State<IsoGameScreen> {
  late IsoGame _game;
  int _wood = 0;
  int _stone = 0;
  int _food = 10;
  int _turns = 50;
  int _population = 5;
  String _status = '';
  final List<String> _log = [];
  bool _showBuildMenu = false;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _game = _createGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dx = -600.0 + MediaQuery.of(context).size.width / 2 - 40;
      final dy = -340.0 + MediaQuery.of(context).size.height / 3;
      _transformController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(1.0);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  IsoGame _createGame() {
    return IsoGame(
      gridSize: 15,
      onUpdate: (w, s, f, t, p, status) => setState(() {
        _wood = w;
        _stone = s;
        _food = f;
        _turns = t;
        _population = p;
        if (status.isNotEmpty) _status = status;
      }),
      onLog: (msg) => setState(() {
        _log.insert(0, 'День ${50 - _turns}: $msg');
        if (_log.length > 50) _log.removeLast();
      }),
      onGameEnd: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Игра окончена'),
            content: Text(
                '🌲 Дерево: $_wood\n🪨 Камень: $_stone\n🍗 Еда: $_food\n👥 Население: $_population\n🏠 Построек: ${_game.countBuildings()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _game = _createGame();
                    _log.clear();
                    _showBuildMenu = false;
                  });
                },
                child: const Text('Новая игра'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поселение'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('Осталось: $_turns ходов', style: const TextStyle(color: Colors.black, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.brown.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _res('🌲', '$_wood', Colors.brown),
                _res('🪨', '$_stone', Colors.grey),
                _res('🍗', '$_food', Colors.red),
                _res('👥', '$_population', Colors.blue),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(_status.isNotEmpty ? _status : 'Выберите действие',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minZoom = (constraints.maxWidth / 1500).clamp(0.2, 1.0);
                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: minZoom,
                  maxScale: 3.0,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: SizedBox(
                    width: 2800,
                    height: 2800,
                    child: GameWidget(game: _game),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _btn('🌲 Добыть', Colors.green.shade700, () => _game.chopWood()),
                  const SizedBox(width: 6),
                  _btn('⛰️ Камень', Colors.grey.shade700, () => _game.mineStone()),
                  const SizedBox(width: 6),
                  _btn('🔨 Строить', Colors.orange, () => setState(() => _showBuildMenu = !_showBuildMenu)),
                ],
              ),
            ),
          ),
          if (_showBuildMenu)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBtn(BuildingType.house, '🏠', 'Дом'),
                  _buildBtn(BuildingType.sawmill, '🪚', 'Пилка'),
                  _buildBtn(BuildingType.storage, '📦', 'Склад'),
                  _buildBtn(BuildingType.castle, '🏰', 'Замок'),
                ],
              ),
            ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade100,
            child: ListView(
              children: _log.take(2).map((l) => Text(l, style: const TextStyle(fontSize: 11))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _res(String e, String v, Color c) => Row(children: [
    Text(e, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 4),
    Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15)),
  ]);

  Widget _btn(String label, Color color, VoidCallback onPressed) => ElevatedButton(
    onPressed: _turns > 0 ? onPressed : null,
    style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
    child: Text(label, style: const TextStyle(fontSize: 13)),
  );

  Widget _buildBtn(BuildingType type, String emoji, String name) {
    final cost = buildingCosts[type]!;
    return GestureDetector(
      onTap: () => _game.build(type),
      child: Tooltip(
        message: '$name: 🌲${cost['wood']} 🪨${cost['stone']} 🍗${cost['food']}',
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(name, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}