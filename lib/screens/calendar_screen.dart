import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import 'add_user_screen.dart';
import 'all_users_screen.dart';
import 'day_table_screen.dart';
import 'dev_screen.dart';
import 'manage_schedule_screen.dart';
import 'user_profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  Map<String, int> _workerCountByDay = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final year = _currentMonth.year;
    final month = _currentMonth.month.toString().padLeft(2, '0');
    final prefix = '$year-$month';

    final snapshot = await FirebaseFirestore.instance
        .collection('schedule')
        .where('date', isGreaterThanOrEqualTo: '$prefix-01')
        .where('date', isLessThanOrEqualTo: '$prefix-31')
        .get();

    final counts = <String, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userIds = List<String>.from(data['user_ids'] ?? []);
      counts[data['date']] = userIds.length;
    }

    setState(() {
      _workerCountByDay = counts;
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadSchedule();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadSchedule();
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month];
  }

  String _getDateStr(int day) {
    return '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.currentRole;
    final appUser = authProvider.appUser;

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getMonthName(_currentMonth.month)} ${_currentMonth.year}'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        actions: [
          // Профиль пользователя
          if (appUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Chip(
                  avatar: CircleAvatar(
                    radius: 14,
                    backgroundColor: _getRoleColor(role),
                    child: Text(
                      _getInitials(appUser.fullName),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(
                    appUser.fullName.isNotEmpty ? appUser.fullName : appUser.email,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          // Боковая панель для admin/developer
          if (role == AppRole.admin || role == AppRole.developer)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      endDrawer: (role == AppRole.admin || role == AppRole.developer)
          ? _buildDrawer(context, role)
          : null,
      body: Column(
        children: [
          // Заголовки дней недели
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                  .map((d) => Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 13)),
                ),
              ))
                  .toList(),
            ),
          ),
          // Сетка дней
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
              ),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                final dayIndex = index - firstWeekday + 2;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const SizedBox();
                }

                final dateStr = _getDateStr(dayIndex);
                final count = _workerCountByDay[dateStr] ?? 0;
                final today = DateTime.now();
                final isToday = dayIndex == today.day &&
                    _currentMonth.month == today.month &&
                    _currentMonth.year == today.year;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayTableScreen(date: dateStr),
                      ),
                    );
                  },
                  onLongPress: (role == AppRole.admin || role == AppRole.developer)
                      ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageScheduleScreen(date: dateStr),
                      ),
                    );
                    _loadSchedule(); // обновляем счётчики после возврата
                  }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.blue.shade50 : Colors.white,
                      border: Border.all(
                        color: isToday ? Colors.blue : Colors.grey.shade300,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayIndex',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Colors.blue : Colors.black87,
                          ),
                        ),
                        if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(
            heroTag: 'prev',
            onPressed: _prevMonth,
            child: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.small(
            heroTag: 'next',
            onPressed: _nextMonth,
            child: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppRole role) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Настройки', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Настройка таблицы'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Все сотрудники'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Добавить пользователя'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
            },
          ),
          if (role == AppRole.developer)
            ListTile(
              leading: const Icon(Icons.build, color: Colors.red),
              title: const Text('Инструменты разработчика'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DevScreen()));
              },
            ),
          const Spacer(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Календарь — главный экран', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.developer: return Colors.red;
      case AppRole.user: return Colors.blue;
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }
}