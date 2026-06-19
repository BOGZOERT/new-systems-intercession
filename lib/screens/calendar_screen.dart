import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/table_provider.dart';
import '../models/worker_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  Map<int, List<WorkerModel>> _shiftsByDay = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadData();
  }

  void _loadData() {
    final allWorkers = context.read<TableProvider>().allWorkers;

    // Распределяем работников по дням месяца (упрощённо: по ID)
    _shiftsByDay = {};
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      _shiftsByDay[day] = [];
    }

    // Распределяем работников по дням
    int workerIndex = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      if (workerIndex >= allWorkers.length) break;
      // Каждый день выходит несколько человек (циклично)
      final workersForDay = <WorkerModel>[];
      final count = (allWorkers.length / daysInMonth).ceil() + 1;
      for (int i = 0; i < count && workerIndex < allWorkers.length; i++) {
        workersForDay.add(allWorkers[workerIndex]);
        workerIndex++;
      }
      _shiftsByDay[day] = workersForDay;
    }

    setState(() {});
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(_currentMonth.month);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text('$monthName ${_currentMonth.year}'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.85,
        ),
        itemCount: firstWeekday - 1 + daysInMonth,
        itemBuilder: (context, index) {
          final dayIndex = index - firstWeekday + 2;
          if (dayIndex < 1 || dayIndex > daysInMonth) {
            return const SizedBox();
          }

          final workers = _shiftsByDay[dayIndex] ?? [];
          final isToday = dayIndex == DateTime.now().day &&
              _currentMonth.month == DateTime.now().month &&
              _currentMonth.year == DateTime.now().year;

          return GestureDetector(
            onTap: () => _showDayDetails(context, dayIndex, workers),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue.shade50 : Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2),
                    color: isToday ? Colors.blue : Colors.grey.shade100,
                    child: Text(
                      '$dayIndex',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isToday ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildCategoryCircles(workers),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCircles(List<WorkerModel> workers) {
    if (workers.isEmpty) return const SizedBox();

    final categories = <int, int>{}; // категория -> количество
    for (var w in workers) {
      categories[w.category] = (categories[w.category] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: categories.entries.map((e) {
          return CircleAvatar(
            radius: 10,
            backgroundColor: _getCategoryColor(e.key),
            child: Text(
              '${e.value}',
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDayDetails(BuildContext context, int day, List<WorkerModel> workers) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'День $day — ${workers.length} чел.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (workers.isEmpty)
                const Text('Нет данных', style: TextStyle(color: Colors.grey))
              else
                ..._groupByCategory(workers).entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: _getCategoryColor(entry.key),
                              child: Text(
                                '${entry.key}',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key} категория (${entry.value.length} чел.)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...entry.value.map((w) => Padding(
                          padding: const EdgeInsets.only(left: 36, top: 2),
                          child: Text(w.lastName, style: const TextStyle(fontSize: 14)),
                        )),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Map<int, List<WorkerModel>> _groupByCategory(List<WorkerModel> workers) {
    final map = <int, List<WorkerModel>>{};
    for (var w in workers) {
      map.putIfAbsent(w.category, () => []).add(w);
    }
    // Сортируем по категориям
    final sortedKeys = map.keys.toList()..sort();
    return {for (var k in sortedKeys) k: map[k]!};
  }

  Color _getCategoryColor(int category) {
    switch (category) {
      case 4: return Colors.blue;
      case 5: return Colors.green;
      case 6: return Colors.orange;
      case 7: return Colors.purple;
      case 8: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month];
  }
}