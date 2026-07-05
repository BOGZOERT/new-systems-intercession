import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import '../services/version_service.dart';
import '../widgets/user_avatar.dart';
import 'add_user_screen.dart';
import 'all_users_screen.dart';
import 'choice_screen.dart';
import 'calendar_settings_screen.dart';
import 'day_table_screen.dart';
import 'dev_screen.dart';
import 'manage_schedule_screen.dart';
import 'swaps_screen.dart';
import 'month_summary_screen.dart';
import 'user_profile_screen.dart';
import 'privacy_policy_screen.dart';

class CalendarScreen extends StatefulWidget {
  final String? organizationId;

  const CalendarScreen({super.key, this.organizationId});

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

    if (widget.organizationId != null && widget.organizationId!.isNotEmpty) {
      // Сначала обновляем organizationId, потом загружаем данные
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().updateOrganizationId(widget.organizationId!);
        _loadSchedule(); // ← загрузка после обновления
      });
    } else {
      _loadSchedule(); // ← личный режим — загружаем сразу
    }
  }

  String? get _organizationId {
    final currentUser = context.read<AuthProvider>().appUser;
    final isOrganization = currentUser != null && currentUser.organizationId.isNotEmpty;
    return isOrganization ? currentUser!.organizationId : null;
  }

  String get _scheduleCollection {
    final currentUser = context.read<AuthProvider>().appUser;
    final isOrganization = currentUser != null && currentUser.organizationId.isNotEmpty;
    return isOrganization ? 'schedule' : 'personal_schedule';
  }

  Future<void> _loadSchedule() async {
    final year = _currentMonth.year;
    final month = _currentMonth.month.toString().padLeft(2, '0');
    final prefix = '$year-$month';
    final currentUser = context.read<AuthProvider>().appUser;
    final currentUid = currentUser?.uid ?? '';
    final isOrganization = currentUser != null && currentUser.organizationId.isNotEmpty;
    final collection = _scheduleCollection;
    final orgId = _organizationId;

    var query = FirebaseFirestore.instance
        .collection(collection)
        .where('date', isGreaterThanOrEqualTo: '$prefix-01')
        .where('date', isLessThanOrEqualTo: '$prefix-31');

    if (isOrganization && orgId != null) {
      query = query.where('organization_id', isEqualTo: orgId);
    }

    final snapshot = await query.get();

    final counts = <String, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userIds = List<String>.from(data['user_ids'] ?? []);

      if (isOrganization) {
        counts[data['date']] = userIds.length;
      } else {
        if (currentUid.isNotEmpty && userIds.contains(currentUid)) {
          counts[data['date']] = 1;
        }
      }
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
        builder: (_) => ManageScheduleScreen(
          date: _selectedDates.first,
          selectedDates: _selectedDates.toList(),
          organizationId: _organizationId,
        ),
      ),
    ).then((_) {
      _loadSchedule();
      setState(() {
        _multiSelectMode = false;
        _selectedDates.clear();
      });
    });
  }

  void _onLongPress(String dateStr) async {
    final role = context.read<AuthProvider>().currentRole;
    final currentUser = context.read<AuthProvider>().appUser;
    final isOrganization = currentUser != null && currentUser.organizationId.isNotEmpty;
    final collection = _scheduleCollection;
    final orgId = _organizationId;

    if (isOrganization && (role == AppRole.admin || role == AppRole.developer || role == AppRole.boss)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManageScheduleScreen(date: dateStr, organizationId: orgId),
        ),
      );
      _loadSchedule();
    } else if (currentUser != null) {
      final docRef = FirebaseFirestore.instance.collection(collection).doc(dateStr);
      final doc = await docRef.get();

      List<String> userIds = [];
      if (doc.exists) {
        final data = doc.data()!;
        userIds = List<String>.from(data['user_ids'] ?? []);
      }

      final isAlreadyInShift = userIds.contains(currentUser.uid);

      if (isAlreadyInShift) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Смена ${_formatDate(dateStr)}'),
            content: const Text('Удалить себя из этой смены?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Удалить', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          userIds.remove(currentUser.uid);
          if (userIds.isEmpty) {
            await docRef.delete();
          } else {
            await docRef.update({'user_ids': userIds});
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🗑️ Вы удалены из смены')),
            );
          }
          _loadSchedule();
        }
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Смена ${_formatDate(dateStr)}'),
            content: const Text('Добавить себя на эту смену?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Добавить'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          userIds.add(currentUser.uid);
          final data = <String, dynamic>{
            'date': dateStr,
            'user_ids': userIds,
          };
          if (orgId != null) {
            data['organization_id'] = orgId;
          }
          await docRef.set(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Вы добавлены на смену')),
            );
          }
          _loadSchedule();
        }
      }
    }
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    return '$day ${months[month]} ${parts[0]}';
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
    final isOrganization = appUser != null && appUser.organizationId.isNotEmpty;

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
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < 0) {
              _nextMonth();
            } else if (details.primaryVelocity! > 0) {
              _prevMonth();
            }
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadSchedule,
          child: Column(
            children: [
              if (isOrganization && (role == AppRole.admin || role == AppRole.developer || role == AppRole.boss))
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DayTableScreen(
                                date: dateStr,
                                organizationId: _organizationId,
                                scheduleCollection: _scheduleCollection,
                              ),
                            ),
                          ).then((_) => _loadSchedule());
                        }
                      },
                      onLongPress: _multiSelectMode ? null : () => _onLongPress(dateStr),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade100
                              : isToday
                              ? Colors.blue.shade50
                              : count > 0
                              ? Colors.green.shade50
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : isToday
                                ? Colors.blue
                                : count > 0
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: isSelected || isToday || count > 0 ? 2 : 1,
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
                                color: isSelected ? Colors.blue : (isToday ? Colors.blue : (count > 0 ? Colors.green.shade700 : Colors.black87)),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check, color: Colors.blue, size: 16)
                            else if (count > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        ),
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
    final isOrganization = appUser != null && appUser.organizationId.isNotEmpty;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  isOrganization ? 'Режим организации' : 'Личный календарь',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isOrganization)
                  _drawerItem(Icons.people, 'Все сотрудники', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()));
                  }),

                if (isOrganization && (role == AppRole.admin || role == AppRole.developer))
                  _drawerItem(Icons.person_add, 'Добавить пользователя', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
                  }),

                if (isOrganization)
                  _drawerItem(Icons.summarize, 'Итоги месяца', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthSummaryScreen()));
                  }),

                if (isOrganization)
                  _drawerItem(Icons.swap_horiz, 'Замены', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapsScreen()));
                  }),

                if (isOrganization && role == AppRole.developer)
                  _drawerItem(Icons.build, 'Инструменты разработчика', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DevScreen()));
                  }, color: Colors.red),

                const Divider(),

                _drawerItem(Icons.settings, 'Настройки календаря', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarSettingsScreen()));
                }),

                _drawerItem(Icons.swap_horiz, 'Сменить режим', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ChoiceScreen()),
                  );
                }, color: Colors.orange),

                _drawerItem(Icons.description, 'Пользовательское соглашение', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                }),
              ],
            ),
          ),

          const Divider(height: 1),
          _drawerItem(Icons.logout, 'Выйти', () async {
            Navigator.pop(context);
            final authProvider = context.read<AuthProvider>();
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          }, color: Colors.red),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Версия ${VersionService.versionString}',
              style: const TextStyle(color: Colors.black54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}