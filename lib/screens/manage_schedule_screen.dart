import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/users_provider.dart';
import '../widgets/user_avatar.dart';

class ManageScheduleScreen extends StatefulWidget {
  final String date;

  const ManageScheduleScreen({super.key, required this.date});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  List<String> _selectedUserIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection('schedule')
        .doc(widget.date)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _selectedUserIds = List<String>.from(data['user_ids'] ?? []);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('schedule')
        .doc(widget.date)
        .set({
      'date': widget.date,
      'user_ids': _selectedUserIds,
    });

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Расписание сохранено')),
      );
      Navigator.pop(context);
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

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.developer: return Colors.red;
      case AppRole.user: return Colors.blue;
      case AppRole.boss: return Colors.blue;
    }
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

  String _getRoleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
      case AppRole.admin: return 'Администратор';
      case AppRole.developer: return 'Разработчик';
      case AppRole.boss: return 'Начальник';
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

  @override
  Widget build(BuildContext context) {
    final allUsers = context.watch<UsersProvider>().users;

    // Сортируем по категориям
    final sortedUsers = List<AppUser>.from(allUsers)
      ..sort((a, b) => a.category.compareTo(b.category));

    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание — ${_formatDate(widget.date)}'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Сохранить', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет пользователей', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedUsers.length,
        itemBuilder: (context, index) {
          final user = sortedUsers[index];
          final isSelected = _selectedUserIds.contains(user.uid);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: CheckboxListTile(
              value: isSelected,
              activeColor: _getCategoryColor(user.category),
              title: Text(
                user.fullName.isNotEmpty ? user.fullName : user.email,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(user.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${user.category} кат.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(user.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRoleTitle(user.role),
                    style: TextStyle(fontSize: 11, color: _getRoleColor(user.role)),
                  ),
                ],
              ),
              secondary: UserAvatar(
                user: user,
                radius: 20,
                defaultColor: _getCategoryColor(user.category),
              ),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedUserIds.add(user.uid);
                  } else {
                    _selectedUserIds.remove(user.uid);
                  }
                });
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Выбрано: ${_selectedUserIds.length} чел.', style: const TextStyle(fontSize: 14)),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Сохранить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}