import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';

class RequestSwapScreen extends StatefulWidget {
  const RequestSwapScreen({super.key});

  @override
  State<RequestSwapScreen> createState() => _RequestSwapScreenState();
}

class _RequestSwapScreenState extends State<RequestSwapScreen> {
  String? _selectedDate;
  String? _selectedUserId;
  int _selectedCategory = 4;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    final allUsers = context.watch<UsersProvider>().users;

    // Пользователи выбранной категории (кроме себя)
    final usersInCategory = allUsers
        .where((u) => u.categories.contains(_selectedCategory) && u.uid != currentUser?.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Запросить замену')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Выберите дату смены:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDate ?? 'Нажмите для выбора даты'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 24),

            const Text('По какой категории хотите замену:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [3, 4, 5, 6, 7, 8].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$cat категория'),
                      selected: isSelected,
                      selectedColor: _getCategoryColor(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _getCategoryColor(cat),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (v) {
                        setState(() {
                          _selectedCategory = cat;
                          _selectedUserId = null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Кому отправить запрос:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (usersInCategory.isEmpty)
              const Text('Нет пользователей в этой категории', style: TextStyle(color: Colors.grey))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: usersInCategory.length,
                  itemBuilder: (context, index) {
                    final user = usersInCategory[index];
                    return RadioListTile<String>(
                      title: Text(user.fullName),
                      subtitle: Text('${user.category} категория'),
                      value: user.uid,
                      groupValue: _selectedUserId,
                      onChanged: (v) => setState(() => _selectedUserId = v),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Отправить запрос'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите дату')));
      return;
    }
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите сотрудника')));
      return;
    }

    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    final toUser = context.read<UsersProvider>().users.firstWhere((u) => u.uid == _selectedUserId);

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('swap_requests').add({
        'from_user_id': currentUser.uid,
        'from_user_name': currentUser.fullName,
        'from_category': currentUser.category,
        'date': _selectedDate,
        'to_user_id': toUser.uid,
        'to_user_name': toUser.fullName,
        'to_category': _selectedCategory,
        'status': 'pending',
        'new_date': '',
        'created_at': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Запрос отправлен')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
}