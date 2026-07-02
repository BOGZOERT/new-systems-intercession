import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/online_status.dart';
import 'manage_schedule_screen.dart';
import 'user_profile_screen.dart';

class DayTableScreen extends StatefulWidget {
  final String date;
  final String? organizationId;
  final String scheduleCollection;

  const DayTableScreen({
    super.key,
    required this.date,
    this.organizationId,
    this.scheduleCollection = 'schedule',
  });

  @override
  State<DayTableScreen> createState() => _DayTableScreenState();
}

class _DayTableScreenState extends State<DayTableScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  final _noteController = TextEditingController();
  String _savedNote = '';
  List<Map<String, dynamic>> _swapNotes = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadNote();
    _loadSwapNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    final docId = '${widget.date}_${currentUser.uid}';
    final doc = await FirebaseFirestore.instance.collection('day_notes').doc(docId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _savedNote = data['note'] as String? ?? '';
        _noteController.text = _savedNote;
      });
    }
  }

  Future<void> _saveNote() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    final note = _noteController.text.trim();
    final docId = '${widget.date}_${currentUser.uid}';

    await FirebaseFirestore.instance.collection('day_notes').doc(docId).set({
      'date': widget.date,
      'user_id': currentUser.uid,
      'note': note,
    });

    setState(() {
      _savedNote = note;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Заметка сохранена')),
      );
    }
  }

  Future<void> _loadSwapNotes() async {
    final docId = '${widget.date}_swap';
    final doc = await FirebaseFirestore.instance.collection('day_notes').doc(docId).get();

    final swapNotes = <Map<String, dynamic>>[];

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final note = data['note'] as String? ?? '';
      final lines = note.split('\n');
      for (var line in lines) {
        if (line.contains('🔄 Замена:')) {
          swapNotes.add({'text': line});
        }
      }
    }

    setState(() {
      _swapNotes = swapNotes;
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection(widget.scheduleCollection)
        .doc(widget.date)
        .get();

    List<String> userIds = [];
    if (doc.exists) {
      final data = doc.data()!;
      userIds = List<String>.from(data['user_ids'] ?? []);
    }

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
                    builder: (_) => ManageScheduleScreen(
                      date: widget.date,
                      organizationId: widget.organizationId,
                    ),
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
        onRefresh: () async {
          await _loadUsers();
          await _loadNote();
          await _loadSwapNotes();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    const Icon(Icons.notes, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Мои заметки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_savedNote.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('есть', style: TextStyle(fontSize: 10, color: Colors.green)),
                      ),
                  ],
                ),
                initiallyExpanded: _savedNote.isNotEmpty,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Личная заметка (видна только вам)...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Эта заметка видна только вам',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_noteController.text != _savedNote)
                              ElevatedButton.icon(
                                onPressed: _saveNote,
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('Сохранить'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_swapNotes.isNotEmpty)
              Card(
                child: ExpansionTile(
                  title: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Замены', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text('${_swapNotes.length}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  initiallyExpanded: true,
                  children: [
                    ...(_swapNotes.map((note) => ListTile(
                      leading: const Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
                      title: Text(
                        note['text'] as String? ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ))),
                  ],
                ),
              ),

            if (_swapNotes.isNotEmpty) const SizedBox(height: 12),

            if (_users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
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
              )
            else
              Card(
                child: ExpansionTile(
                  title: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Сотрудники на смене', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text('${_users.length} чел.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  initiallyExpanded: true,
                  children: [
                    ...categories.map((category) {
                      final usersInCategory = grouped[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(category),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$category',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$category категория',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(category),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${usersInCategory.length} чел.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ...usersInCategory.map((user) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getRoleTitle(user.role),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 2),
                                    OnlineStatus(lastActive: user.lastActive),
                                  ],
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
                            ),
                          )),
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}