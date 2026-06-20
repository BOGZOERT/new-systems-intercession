import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  int _currentCategory = 4;
  final Map<int, bool> _categorySelections = {
    4: false,
    5: false,
    6: false,
    7: false,
    8: false,
  };

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart, size: 80, color: Colors.blue.shade700),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Вход' : 'Регистрация',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Таблица смен', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 32),

                if (authProvider.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                if (!_isLogin) ...[
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

                  // Выбор категорий (галочки)
                  const Text('Категории сотрудника',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Выберите все категории, по которым можете работать',
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

                  // Текущая категория на смене
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
                  const SizedBox(height: 16),
                ],

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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : () => _submit(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLogin ? 'Войти' : 'Зарегистрироваться', style: const TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Есть аккаунт? Войти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCategories = _getSelectedCategories();
    if (!_isLogin && selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    bool success;
    if (_isLogin) {
      success = await authProvider.login(email, password);
    } else {
      success = await authProvider.register(email, password, fullName, _currentCategory, selectedCategories);
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
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
}