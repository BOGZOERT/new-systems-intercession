import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/worker_model.dart';
import '../providers/auth_provider.dart';
import '../providers/table_provider.dart';

class WorkerProfileScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  late WorkerModel _worker;
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _photoFile;

  final Map<int, bool> _categorySelections = {
    4: false, 5: false, 6: false, 7: false, 8: false,
  };

  int _currentCategory = 4;

  bool get _canEdit {
    final role = context.read<AuthProvider>().currentRole;
    return role == AppRole.admin || role == AppRole.developer;
  }

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
    _phoneController.text = _worker.phone;
    _fullNameController.text = _worker.lastName;

    for (var cat in _worker.categories) {
      _categorySelections[cat] = true;
    }
    _currentCategory = _worker.category;

    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/worker_${_worker.id}_photo.jpg');
    if (await file.exists()) {
      setState(() {
        _photoFile = file;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canEdit) return;
    if (!_formKey.currentState!.validate()) return;

    final selectedCategories = _categorySelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }

    final updated = _worker.copyWith(
      lastName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      categories: selectedCategories,
      category: _currentCategory,
    );

    await context.read<TableProvider>().updateWorker(_worker.id, updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Данные сохранены')),
      );
      Navigator.pop(context, updated);
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
      appBar: AppBar(
        title: const Text('Профиль сотрудника'),
        actions: [
          if (_canEdit)
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Фото (только просмотр, без редактирования)
              CircleAvatar(
                radius: 60,
                backgroundColor: _getCategoryColor(_worker.category),
                backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                child: _photoFile == null
                    ? Text(
                  _getInitials(_worker.lastName),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(height: 8),
              const Text('Фото сотрудника',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),

              // ФИО
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                readOnly: !_canEdit,
                decoration: InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  filled: !_canEdit,
                  fillColor: _canEdit ? null : Colors.grey.shade100,
                ),
                validator: (v) {
                  if (!_canEdit) return null;
                  if (v == null || v.trim().isEmpty) return 'Введите ФИО';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                initialValue: '${_worker.lastName.toLowerCase().replaceAll(' ', '.')}@mail.com',
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: !_canEdit,
                decoration: InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: '+7 (999) 123-45-67',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                  filled: !_canEdit,
                  fillColor: _canEdit ? null : Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 24),

              // Категории
              const Text('Категории сотрудника',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _canEdit
                    ? 'Выберите все категории, по которым может работать сотрудник'
                    : 'Категории, по которым работает сотрудник',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ..._categorySelections.entries.map((entry) {
                return CheckboxListTile(
                  title: Text('${entry.key} категория'),
                  value: entry.value,
                  activeColor: _getCategoryColor(entry.key),
                  onChanged: _canEdit
                      ? (v) {
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
                  }
                      : null,
                );
              }),
              const SizedBox(height: 16),

              // Текущая категория
              if (_canEdit) ...[
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
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: _getCategoryColor(e.key),
                        ),
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
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.work, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Текущая категория на смене: '),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: _getCategoryColor(_worker.category),
                    ),
                    const SizedBox(width: 6),
                    Text('${_worker.category} категория',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              if (!_canEdit)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Редактирование данных доступно только администратору и разработчику',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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