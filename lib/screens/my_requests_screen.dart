import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  Stream<QuerySnapshot>? _stream;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) {
      setState(() => _error = 'Пользователь не найден');
      return;
    }

    setState(() {
      _stream = FirebaseFirestore.instance
          .collection('swap_requests')
          .where('to_user_id', isEqualTo: currentUser.uid)
          .snapshots();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Запросы на замену')),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    final hasAccess = currentUser.categories.contains(3) ||
        currentUser.role == AppRole.admin ||
        currentUser.role == AppRole.developer;

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Запросы на замену')),
        body: const Center(child: Text('Нет доступа к запросам')),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Запросы на замену')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _setupStream,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Запросы на замену')),
      body: _stream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _setupStream,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Нет запросов',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          // Сортируем вручную
          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['created_at'] as dynamic;
            final bTime = (b.data() as Map<String, dynamic>)['created_at'] as dynamic;
            return bTime.toDate().compareTo(aTime.toDate());
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(
                    data['from_user_name'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('📅 Дата смены: ${data['date']}'),
                      Text('📂 Категория: ${data['from_category']}'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'pending'
                              ? Colors.orange.shade100
                              : status == 'accepted'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status == 'pending'
                              ? '⏳ Ожидает'
                              : status == 'accepted'
                              ? '✅ Принято'
                              : '❌ Отклонено',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status == 'pending'
                                ? Colors.orange.shade800
                                : status == 'accepted'
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _updateStatus(docs[index].id, 'accepted'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _updateStatus(docs[index].id, 'rejected'),
                      ),
                    ],
                  )
                      : Icon(
                    status == 'accepted' ? Icons.check_circle : Icons.cancel,
                    color: status == 'accepted' ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('swap_requests')
          .doc(docId)
          .update({'status': status});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }
}