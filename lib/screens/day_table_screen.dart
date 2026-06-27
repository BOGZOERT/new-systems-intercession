import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_avatar.dart';
import 'manage_schedule_screen.dart';
import 'user_profile_screen.dart';

class DayTableScreen extends StatefulWidget {
  final String date;

  const DayTableScreen({super.key, required this.date});

  @override
  State<DayTableScreen> createState() => _DayTableScreenState();
}

class _DayTableScreenState extends State<DayTableScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final scheduleDoc = await FirebaseFirestore.instance
        .collection('schedule')
        .doc(widget.date)
        .get();

    List<String> userIds = [];
    if (scheduleDoc.exists) {
      final data = scheduleDoc.data()!;
      userIds = List<String>.from(data['user_ids'] ?? []);
    }

    // Ждём пока UsersProvider загрузит данные
    final usersProvider = context.read<UsersProvider>();
    final allUsers = usersProvider.users;

    final users = allUsers.where((u) => userIds.contains(u.uid)).toList();
    users.sort((a, b) => a.category.compareTo(b.category));

    setState(() {
      _users = users;
      _isLoading = false;
    });
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

  Color _getCategoryColor(int category) {
    switch (category) {
      case 3: return Colors.teal;
      case 4: return Colors.blue;
      case 5: return Colors.green;
      case 6: return Colors.orange;
      case 7: return Colors.purple;
      case 8: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getRoleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
      case AppRole.admin: return 'Администратор';
      case AppRole.developer: return 'Разработчик';
      case AppRole.boss: return 'Начальник';
    }
  }

  Map<int, List<AppUser>> _groupByCategory() {
    final map = <int, List<AppUser>>{};
    for (var user in _users) {
      map.putIfAbsent(user.category, () => []).add(user);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentRole;
    final grouped = _groupByCategory();
    final categories = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Смена — ${_formatDate(widget.date)}'),
        actions: [
          if (role == AppRole.admin || role == AppRole.developer || role == AppRole.boss)
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageScheduleScreen(date: widget.date),
                  ),
                );
                _loadUsers();
              },
            ),
          Text('${_users.length} чел.', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Column(
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет данных на эту дату', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Потяните вниз, чтобы обновить', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final usersInCategory = grouped[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$category',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$category категория',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getCategoryColor(category)),
                      ),
                      const Spacer(),
                      Text('${usersInCategory.length} чел.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                ...usersInCategory.map((user) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  child: ListTile(
                    leading: UserAvatar(
                      user: user,
                      radius: 20,
                      defaultColor: _getCategoryColor(user.category),
                    ),
                    title: Text(
                      user.fullName.isNotEmpty ? user.fullName : user.email,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _getRoleTitle(user.role),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(user.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${user.category} кат.',
                        style: TextStyle(
                          color: _getCategoryColor(user.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: user.uid),
                        ),
                      );
                    },
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}