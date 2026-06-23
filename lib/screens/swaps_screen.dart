import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_systems_intercession/screens/request_swap_screen.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import 'my_requests_screen.dart';

class SwapsScreen extends StatefulWidget {
  const SwapsScreen({super.key});

  @override
  State<SwapsScreen> createState() => _SwapsScreenState();
}

class _SwapsScreenState extends State<SwapsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Замены')),
      body: Column(
        children: [
          // Кнопка "Запросить замену" (для всех)
          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('Запросить замену'),
              subtitle: const Text('Отправить запрос на замену смены'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestSwapScreen()),
                );
              },
            ),
          ),

          // Кнопка "Запросы на замену" (для 3 категории, admin, developer, boss)
          if (currentUser.categories.contains(3) ||
              currentUser.role == AppRole.admin ||
              currentUser.role == AppRole.developer ||
              currentUser.role == AppRole.boss)
            Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.inbox, color: Colors.orange),
                title: const Text('Запросы на замену'),
                subtitle: const Text('Входящие запросы от сотрудников'),
                trailing: _buildRequestsBadge(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                  );
                },
              ),
            ),

          // Кнопка "Ответ на замену" (для обычных пользователей)
          if (!currentUser.categories.contains(3) &&
              currentUser.role == AppRole.user)
            Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.mark_email_read, color: Colors.green),
                title: const Text('Ответ на замену'),
                subtitle: const Text('Решение по вашему запросу'),
                trailing: _buildResponseBadge(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SwapResponseScreen()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestsBadge() {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swap_requests')
          .where('to_user_id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildResponseBadge() {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swap_requests')
          .where('from_user_id', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['accepted', 'rejected'])
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

// Заглушка для SwapResponseScreen (создадим отдельно)
class SwapResponseScreen extends StatelessWidget {
  const SwapResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Ответ на замену')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('swap_requests')
            .where('from_user_id', isEqualTo: currentUser.uid)
            .where('status', whereIn: ['accepted', 'rejected'])
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Нет ответов', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text('Дата: ${data['date']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Новая дата: ${data['new_date']}'),
                      Text('Решение: ${status == 'accepted' ? '✅ Принято' : '❌ Отклонено'}'),
                    ],
                  ),
                  trailing: Icon(
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
}