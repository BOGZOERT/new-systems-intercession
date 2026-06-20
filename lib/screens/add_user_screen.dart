import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedRole = 'user';
  int _currentCategory = 4;
  final Map<int, bool> _categorySelections = {
    4: false,
    5: false,
    6: false,
    7: false,
    8: false,
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categorySelections[4] = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  List<int> _getSelectedCategories() {
    return _categorySelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCategories = _getSelectedCategories();
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'role': _selectedRole,
        'category': _currentCategory,
        'categories': selectedCategories,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Пользователь добавлен')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Почта уже используется';
          break;
        case 'weak-password':
          message = 'Пароль слишком слабый (минимум 6 символов)';
          break;
        default:
          message = 'Ошибка: ${e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $message')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить пользователя')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  hintText: 'Иванов Иван Иванович',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите ФИО';
                  if (v.trim().split(' ').length < 2) return 'Введите фамилию и имя';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите email';
                  if (!v.contains('@')) return 'Некорректный email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите пароль';
                  if (v.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Роль',
                  prefixIcon: Icon(Icons.shield),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                  DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                  DropdownMenuItem(value: 'developer', child: Text('Разработчик')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 20),

              // Категории
              const Text('Категории сотрудника',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Выберите все категории, по которым может работать',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              ..._categorySelections.entries.map((entry) {
                return CheckboxListTile(
                  dense: true,
                  title: Text('${entry.key} категория'),
                  value: entry.value,
                  activeColor: _getCategoryColor(entry.key),
                  onChanged: (v) {
                    setState(() {
                      _categorySelections[entry.key] = v ?? false;
                      if (!v! && _currentCategory == entry.key) {
                        final first = _categorySelections.entries.firstWhere(
                              (e) => e.value,
                          orElse: () => const MapEntry(4, true),
                        );
                        _currentCategory = first.key;
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 12),

              // Текущая категория
              DropdownButtonFormField<int>(
                value: _currentCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория на текущей смене',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: _categorySelections.entries
                    .where((e) => e.value)
                    .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      CircleAvatar(radius: 10, backgroundColor: _getCategoryColor(e.key)),
                      const SizedBox(width: 8),
                      Text('${e.key} категория'),
                    ],
                  ),
                ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _currentCategory = v);
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addUser,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add),
                label: const Text('Добавить пользователя'),
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
}