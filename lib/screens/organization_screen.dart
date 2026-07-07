import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'calendar_screen.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedOrgId;
  String? _selectedOrgName;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterOrganization() async {
    if (_selectedOrgId == null) {
      setState(() => _errorMessage = 'Выберите организацию');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(_selectedOrgId)
          .get();

      if (!orgDoc.exists) {
        setState(() => _errorMessage = 'Организация не найдена');
        _isLoading = false;
        return;
      }

      final orgData = orgDoc.data()!;
      final correctPassword = orgData['password'] as String? ?? '';

      if (_passwordController.text != correctPassword) {
        setState(() => _errorMessage = 'Неверный пароль организации');
        _isLoading = false;
        return;
      }

      final currentUser = context.read<AuthProvider>().firebaseUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'organization_id': _selectedOrgId});
      }

      print('=== ВХОД В ОРГАНИЗАЦИЮ ===');
      print('selectedOrgId: $_selectedOrgId');
      print('currentUser uid: ${currentUser?.uid}');
      print('mounted: $mounted');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CalendarScreen(
              key: UniqueKey(),
              organizationId: _selectedOrgId!,
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business, size: 80, color: Colors.blue.shade700),
                const SizedBox(height: 16),
                const Text(
                  'Выбор организации',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Выберите организацию и введите пароль',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
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
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('organizations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final orgs = snapshot.data!.docs;

                    if (orgs.isEmpty) {
                      return const Text(
                        'Нет доступных организаций',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return Column(
                      children: orgs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] as String? ?? '';
                        final isSelected = _selectedOrgId == doc.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: RadioListTile<String>(
                            value: doc.id,
                            groupValue: _selectedOrgId,
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Доступ по паролю'),
                            secondary: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _selectedOrgId = v;
                                _selectedOrgName = name;
                                _errorMessage = null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль организации',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enterOrganization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Войти', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}