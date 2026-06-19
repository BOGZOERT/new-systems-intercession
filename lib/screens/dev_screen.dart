import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инструменты разработчика'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Карточка: заполнить базу
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📦 Заполнить базу тестовыми данными',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Добавит 10 сотрудников с разными статусами и категориями. '
                          'Существующие данные не удаляются, документы перезаписываются по ID.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _seedDatabase(context),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Заполнить базу'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Карточка: очистить базу
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗑️ Очистить коллекцию workers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Удалит все документы из коллекции workers.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _clearDatabase(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Очистить базу'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Карточка: информация
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Статистика базы',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _BuildStats(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDatabase(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final workers = FirebaseFirestore.instance.collection('workers');

      final data = [
        {
          'last_name': 'Иванов Иван Иванович',
          'total_shifts': 15, 'must_give': 2, 'overtime_hours': 8,
          'shift_given': true, 'absence_reason': '', 'category': 4,
          'categories': [4, 5], 'phone': '+7 (900) 111-22-33', 'photo_url': '',
        },
        {
          'last_name': 'Петров Пётр Петрович',
          'total_shifts': 12, 'must_give': 3, 'overtime_hours': 0,
          'shift_given': false, 'absence_reason': 'sick', 'category': 5,
          'categories': [5], 'phone': '+7 (900) 222-33-44', 'photo_url': '',
        },
        {
          'last_name': 'Сидорова Анна Сергеевна',
          'total_shifts': 10, 'must_give': 5, 'overtime_hours': 12,
          'shift_given': false, 'absence_reason': 'vacation', 'category': 6,
          'categories': [6, 7], 'phone': '+7 (900) 333-44-55', 'photo_url': '',
        },
        {
          'last_name': 'Козлов Дмитрий Алексеевич',
          'total_shifts': 20, 'must_give': 1, 'overtime_hours': 4,
          'shift_given': false, 'absence_reason': '', 'category': 7,
          'categories': [7, 8], 'phone': '+7 (900) 444-55-66', 'photo_url': '',
        },
        {
          'last_name': 'Морозова Елена Викторовна',
          'total_shifts': 18, 'must_give': 0, 'overtime_hours': 16,
          'shift_given': true, 'absence_reason': '', 'category': 8,
          'categories': [8], 'phone': '+7 (900) 555-66-77', 'photo_url': '',
        },
        {
          'last_name': 'Волков Сергей Николаевич',
          'total_shifts': 14, 'must_give': 4, 'overtime_hours': 2,
          'shift_given': false, 'absence_reason': 'sick', 'category': 4,
          'categories': [4], 'phone': '+7 (900) 666-77-88', 'photo_url': '',
        },
        {
          'last_name': 'Зайцева Ольга Павловна',
          'total_shifts': 16, 'must_give': 2, 'overtime_hours': 6,
          'shift_given': true, 'absence_reason': '', 'category': 5,
          'categories': [5, 6], 'phone': '+7 (900) 777-88-99', 'photo_url': '',
        },
        {
          'last_name': 'Медведев Андрей Игоревич',
          'total_shifts': 11, 'must_give': 6, 'overtime_hours': 0,
          'shift_given': false, 'absence_reason': 'vacation', 'category': 6,
          'categories': [6], 'phone': '+7 (900) 888-99-00', 'photo_url': '',
        },
        {
          'last_name': 'Лисицына Татьяна Михайловна',
          'total_shifts': 19, 'must_give': 1, 'overtime_hours': 10,
          'shift_given': true, 'absence_reason': '', 'category': 7,
          'categories': [7], 'phone': '+7 (900) 999-00-11', 'photo_url': '',
        },
        {
          'last_name': 'Бобров Александр Владимирович',
          'total_shifts': 13, 'must_give': 3, 'overtime_hours': 14,
          'shift_given': false, 'absence_reason': '', 'category': 8,
          'categories': [8, 4], 'phone': '+7 (900) 000-11-22', 'photo_url': '',
        },
      ];

      for (var i = 0; i < data.length; i++) {
        await workers.doc('${i + 1}').set(data[i]);
      }

      Navigator.pop(context); // убираем загрузку

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ База заполнена! 10 записей добавлено.')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  Future<void> _clearDatabase(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Удалить ВСЕ документы из коллекции workers?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final workers = FirebaseFirestore.instance.collection('workers');
      final snapshot = await workers.get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Удалено документов: ${snapshot.docs.length}')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }
}

/// Виджет-карточка со статистикой
class _BuildStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Загрузка...');
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;

        if (total == 0) {
          return const Text('Коллекция пустая', style: TextStyle(color: Colors.grey));
        }

        final sick = docs.where((d) => d['absence_reason'] == 'sick').length;
        final vacation = docs.where((d) => d['absence_reason'] == 'vacation').length;
        final given = docs.where((d) => d['shift_given'] == true).length;

        // Статистика по категориям
        final cat4 = docs.where((d) => d['category'] == 4).length;
        final cat5 = docs.where((d) => d['category'] == 5).length;
        final cat6 = docs.where((d) => d['category'] == 6).length;
        final cat7 = docs.where((d) => d['category'] == 7).length;
        final cat8 = docs.where((d) => d['category'] == 8).length;

        return Column(
          children: [
            _statRow('Всего сотрудников', '$total'),
            _statRow('Отдали смену', '$given'),
            _statRow('Болеют', '$sick'),
            _statRow('В отпуске', '$vacation'),
            _statRow('Не вышли без причины', '${total - given - sick - vacation}'),
            const Divider(),
            _statRow('4 категория', '$cat4'),
            _statRow('5 категория', '$cat5'),
            _statRow('6 категория', '$cat6'),
            _statRow('7 категория', '$cat7'),
            _statRow('8 категория', '$cat8'),
          ],
        );
      },
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}