import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/users_provider.dart';

class MonthPaymentScreen extends StatefulWidget {
  final String month;

  const MonthPaymentScreen({super.key, required this.month});

  @override
  State<MonthPaymentScreen> createState() => _MonthPaymentScreenState();
}

class _MonthPaymentScreenState extends State<MonthPaymentScreen> {
  bool _isSaving = false;
  bool _isLoading = true;

  int _selectedCategory = 4;
  int _selectedWeek = 0;
  String? _selectedUserId;

  final Map<String, Map<int, String>> _replacements = {};
  List<List<int>> _weeks = [];

  List<AppUser> get _usersInCategory {
    final allUsers = context.read<UsersProvider>().users;
    return allUsers.where((u) => u.categories.contains(_selectedCategory)).toList();
  }

  List<AppUser> get _allUsers => context.read<UsersProvider>().users;

  @override
  void initState() {
    super.initState();
    _buildWeeks();
    _loadData();
  }

  void _buildWeeks() {
    final parts = widget.month.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;

    _weeks = [];
    List<int> currentWeek = [];

    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(0);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(day);
      if (currentWeek.length == 7 || day == daysInMonth) {
        while (currentWeek.length < 7) {
          currentWeek.add(0);
        }
        _weeks.add(List<int>.from(currentWeek));
        currentWeek = [];
      }
    }

    if (_selectedWeek >= _weeks.length) _selectedWeek = 0;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    for (var user in _allUsers) {
      _replacements[user.uid] = {};
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('month_summaries')
        .where('month', isEqualTo: widget.month)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawEntries = data['payment_entries'];
      final paymentEntries = <Map<String, dynamic>>[];
      if (rawEntries is List) {
        for (var entry in rawEntries) {
          if (entry is Map<String, dynamic>) {
            paymentEntries.add(entry);
          } else if (entry is Map) {
            paymentEntries.add(Map<String, dynamic>.from(entry));
          }
        }
      }

      for (var entry in paymentEntries) {
        final dateParts = (entry['date'] as String).split('-');
        final day = int.parse(dateParts[2]);
        final userId = data['user_id'] as String;
        final replacementUserId = entry['replacement_user_id'] as String? ?? '';
        if (_replacements.containsKey(userId)) {
          _replacements[userId]![day] = replacementUserId;
        }
      }
    }

    if (_usersInCategory.isNotEmpty && _selectedUserId == null) {
      _selectedUserId = _usersInCategory.first.uid;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final parts = widget.month.split('-');

    for (var user in _allUsers) {
      final entries = <Map<String, dynamic>>[];
      final userReplacements = Map<int, String>.from(_replacements[user.uid] ?? {});

      for (var day in userReplacements.keys) {
        final replacementId = userReplacements[day]!;
        if (replacementId.isNotEmpty) {
          final replacementUser = _allUsers.firstWhere(
                (u) => u.uid == replacementId,
            orElse: () => user,
          );
          final dateStr =
              '${parts[0]}-${parts[1].toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          entries.add({
            'replaced_user': user.fullName,
            'replaced_user_id': user.uid,
            'replacement_user': replacementUser.fullName,
            'replacement_user_id': replacementId,
            'count': 1,
            'date': dateStr,
            'type': 'payment',
          });
        }
      }

      final docId = '${widget.month}_${user.uid}';
      final docRef = FirebaseFirestore.instance.collection('month_summaries').doc(docId);
      final doc = await docRef.get();

      if (doc.exists) {
        final existingData = doc.data()!;
        final rawFact = existingData['fact_entries'];
        final factEntries = <Map<String, dynamic>>[];
        if (rawFact is List) {
          for (var entry in rawFact) {
            if (entry is Map<String, dynamic>) {
              factEntries.add(entry);
            } else if (entry is Map) {
              factEntries.add(Map<String, dynamic>.from(entry));
            }
          }
        }
        final totalShifts = (existingData['total_shifts'] as num?)?.toInt() ?? 0;
        final ratePerShift = (existingData['rate_per_shift'] as num?)?.toDouble() ?? 0;
        final totalEarnings = (existingData['total_earnings'] as num?)?.toDouble() ?? 0;

        await docRef.set({
          'user_id': user.uid,
          'month': widget.month,
          'total_shifts': totalShifts,
          'rate_per_shift': ratePerShift,
          'total_earnings': totalEarnings,
          'fact_entries': factEntries,
          'payment_entries': entries,
        });
      } else {
        await docRef.set({
          'user_id': user.uid,
          'month': widget.month,
          'total_shifts': 0,
          'rate_per_shift': 0,
          'total_earnings': 0,
          'fact_entries': [],
          'payment_entries': entries,
        });
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Итоги сохранены')),
      );
      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Итоги выходов — ${widget.month}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentWeek = _weeks.isNotEmpty ? _weeks[_selectedWeek] : <int>[];
    final selectedUserId = _selectedUserId;
    final selectedUser = selectedUserId != null
        ? _allUsers.firstWhere(
          (u) => u.uid == selectedUserId,
      orElse: () => _allUsers.first,
    )
        : _allUsers.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Итоги выходов — ${widget.month}'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Сохранить', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Категория: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [3, 4, 5, 6, 7, 8].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$cat'),
                            selected: isSelected,
                            selectedColor: _getCategoryColor(cat),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : _getCategoryColor(cat),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (v) {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedUserId = _usersInCategory.isNotEmpty ? _usersInCategory.first.uid : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_usersInCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: selectedUserId != null && _usersInCategory.any((u) => u.uid == selectedUserId)
                    ? selectedUserId
                    : (_usersInCategory.isNotEmpty ? _usersInCategory.first.uid : null),
                decoration: const InputDecoration(
                  labelText: 'Сотрудник',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _usersInCategory.map((user) {
                  return DropdownMenuItem(
                    value: user.uid,
                    child: Text(user.fullName),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedUserId = v!);
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedWeek > 0 ? () => setState(() => _selectedWeek--) : null,
                ),
                Text(
                  'Неделя ${_selectedWeek + 1} из ${_weeks.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedWeek < _weeks.length - 1 ? () => setState(() => _selectedWeek++) : null,
                ),
              ],
            ),
          ),

          Expanded(
            child: _usersInCategory.isEmpty
                ? const Center(child: Text('Нет пользователей в категории'))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                          .map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = currentWeek[index];
                      if (day == 0) return const SizedBox();

                      final replacementId = selectedUserId != null
                          ? (_replacements[selectedUserId]?[day] ?? '')
                          : '';
                      final replacementUser = replacementId.isNotEmpty
                          ? _allUsers.firstWhere((u) => u.uid == replacementId, orElse: () => _allUsers.first)
                          : null;

                      return Card(
                        margin: const EdgeInsets.all(2),
                        child: InkWell(
                          onTap: () => _showReplacementPicker(day),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                if (replacementUser != null)
                                  Expanded(
                                    child: Text(
                                      _getInitials(replacementUser.fullName),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getCategoryColor(replacementUser.category),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else
                                  const Text('—', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReplacementPicker(int day) async {
    final selectedUserId = _selectedUserId;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Кто заменил ${_getDayString(day)}?'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                final isSelected = selectedUserId != null &&
                    _replacements[selectedUserId]?[day] == user.uid;
                return ListTile(
                  title: Text(user.fullName),
                  subtitle: Text('${user.category} категория'),
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(user.category),
                    child: Text(
                      _getInitials(user.fullName),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(ctx, user.uid),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Очистить'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );

    if (result != null && selectedUserId != null) {
      setState(() {
        _replacements[selectedUserId] ??= {};
        _replacements[selectedUserId]![day] = result;
      });
    }
  }

  String _getDayString(int day) {
    final parts = widget.month.split('-');
    return '$day.${parts[1]}.${parts[0]}';
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