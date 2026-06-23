import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import '../services/version_service.dart';
import '../widgets/user_avatar.dart';
import 'add_user_screen.dart';
import 'all_users_screen.dart';
import 'day_table_screen.dart';
import 'dev_screen.dart';
import 'manage_schedule_screen.dart';
import 'swaps_screen.dart';
import 'user_profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  Map<String, int> _workerCountByDay = {};
  bool _multiSelectMode = false;
  final Set<String> _selectedDates = {};

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

  void _toggleMultiSelect() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) _selectedDates.clear();
    });
  }

  void _assignSelectedDates() {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну дату')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageScheduleScreen(date: _selectedDates.first, selectedDates: _selectedDates.toList()),
      ),
    ).then((_) {
      _loadSchedule();
      setState(() {
        _multiSelectMode = false;
        _selectedDates.clear();
      });
    });
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
        actions: [
          if (appUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                borderRadius: BorderRadius.circular(20),
                child: Chip(
                  avatar: UserAvatar(user: appUser, radius: 14),
                  label: Text(appUser.fullName.isNotEmpty ? appUser.fullName : appUser.email, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(context, role, appUser),
      body: Column(
        children: [
          // Режим выбора дат (для admin/developer/boss)
          if (role == AppRole.admin || role == AppRole.developer || role == AppRole.boss)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _toggleMultiSelect,
                    icon: Icon(_multiSelectMode ? Icons.close : Icons.date_range),
                    label: Text(_multiSelectMode ? 'Отмена' : 'Выбрать даты'),
                  ),
                  const Spacer(),
                  if (_multiSelectMode && _selectedDates.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _assignSelectedDates,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: Text('Назначить (${_selectedDates.length})'),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                if (dayIndex < 1 || dayIndex > daysInMonth) return const SizedBox();

                final dateStr = _getDateStr(dayIndex);
                final count = _workerCountByDay[dateStr] ?? 0;
                final today = DateTime.now();
                final isToday = dayIndex == today.day && _currentMonth.month == today.month && _currentMonth.year == today.year;
                final isSelected = _selectedDates.contains(dateStr);

                return GestureDetector(
                  onTap: () {
                    if (_multiSelectMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedDates.remove(dateStr);
                        } else {
                          _selectedDates.add(dateStr);
                        }
                      });
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DayTableScreen(date: dateStr)));
                    }
                  },
                  onLongPress: _multiSelectMode
                      ? null
                      : () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ManageScheduleScreen(date: dateStr)));
                    _loadSchedule();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade100
                          : isToday
                          ? Colors.blue.shade50
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : isToday
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: isSelected || isToday ? 2 : 1,
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
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blue : (isToday ? Colors.blue : Colors.black87),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.blue, size: 16)
                        else if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
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
      floatingActionButton: _multiSelectMode
          ? null
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(heroTag: 'prev', onPressed: _prevMonth, child: const Icon(Icons.chevron_left)),
          const SizedBox(width: 16),
          FloatingActionButton.small(heroTag: 'next', onPressed: _nextMonth, child: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppRole role, AppUser? appUser) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Меню', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Все сотрудники'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()));
            },
          ),
          if (role == AppRole.admin || role == AppRole.developer)
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Добавить пользователя'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
              },
            ),
          // Замены (общий экран)
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Замены'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapsScreen()));
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
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Календарь — главный экран', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Версия ${VersionService.versionString}', style: const TextStyle(color: Colors.black, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}