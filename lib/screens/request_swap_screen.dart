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
  final _formKey = GlobalKey<FormState>();
  String? _selectedDate;
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    final allUsers = context.watch<UsersProvider>().users;
    final users3Category = allUsers
        .where((u) => u.categories.contains(3) && u.uid != currentUser?.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Запросить замену')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Выберите дату смены:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Выбор даты
              ElevatedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate ?? 'Нажмите для выбора даты'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Кому отправить запрос (3 категория):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (users3Category.isEmpty)
                const Text('Нет пользователей с 3 категорией',
                    style: TextStyle(color: Colors.grey))
              else
                ...users3Category.map((user) => RadioListTile<String>(
                  title: Text(user.fullName),
                  subtitle: Text('3 категория'),
                  value: user.uid,
                  groupValue: _selectedUserId,
                  onChanged: (v) => setState(() => _selectedUserId = v),
                )),

              const SizedBox(height: 24),

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату')),
      );
      return;
    }
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите кому отправить запрос')),
      );
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
        'status': 'pending',
        'created_at': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Запрос отправлен')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}