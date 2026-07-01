import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/version_service.dart';
import 'privacy_policy_screen.dart';

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
  bool _obscurePassword = true;
  bool _isForgotPassword = false;
  bool _privacyAccepted = false;
  int _currentCategory = 4;
  final Map<int, bool> _categorySelections = {
    3: false,
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

    if (_isForgotPassword) {
      return _buildForgotPasswordScreen(authProvider);
    }

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
                  const SizedBox(height: 8),

                  // Галочка согласия
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _privacyAccepted,
                        onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                          ),
                          child: const Text(
                            'Я принимаю условия пользовательского соглашения',
                            style: TextStyle(fontSize: 13, color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    if (v.length < 6) return 'Минимум 6 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isForgotPassword = true;
                          authProvider.clearError();
                        });
                      },
                      child: const Text(
                        'Забыли пароль?',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 24),

                Text(
                  'Версия ${VersionService.versionString}',
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordScreen(AuthProvider authProvider) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 80, color: Colors.blue.shade700),
                const SizedBox(height: 16),
                const Text(
                  'Восстановление пароля',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Введите email, и мы отправим ссылку для сброса пароля',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (authProvider.resetMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      authProvider.resetMessage!,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),

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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        await authProvider.resetPassword(_emailController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Отправить ссылку', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isForgotPassword = false;
                      authProvider.clearError();
                    });
                  },
                  child: const Text('← Вернуться ко входу'),
                ),

                const SizedBox(height: 24),

                Text(
                  'Версия ${VersionService.versionString}',
                  style: const TextStyle(color: Colors.black, fontSize: 12),
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

    if (!_isLogin && !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Примите пользовательское соглашение')),
      );
      return;
    }

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