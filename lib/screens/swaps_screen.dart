import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'my_requests_screen.dart';
import 'request_swap_screen.dart';

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
          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('Запросить замену'),
              subtitle: const Text('Отправить запрос на замену смены'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestSwapScreen()));
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.inbox, color: Colors.orange),
              title: const Text('Запросы на замену'),
              subtitle: const Text('Входящие запросы от сотрудников'),
              trailing: _buildRequestsBadge(),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen()));
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.mark_email_read, color: Colors.green),
              title: const Text('Ответ на замену'),
              subtitle: const Text('Решение по вашему запросу'),
              trailing: _buildResponseBadge(),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapResponseScreen()));
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

    return FutureBuilder<int>(
      future: _getResponseCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Future<int> _getResponseCount() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return 0;

    final accepted = await FirebaseFirestore.instance
        .collection('swap_requests')
        .where('from_user_id', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final rejected = await FirebaseFirestore.instance
        .collection('swap_requests')
        .where('from_user_id', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'rejected')
        .get();

    return accepted.docs.length + rejected.docs.length;
  }
}

class SwapResponseScreen extends StatefulWidget {
  const SwapResponseScreen({super.key});

  @override
  State<SwapResponseScreen> createState() => _SwapResponseScreenState();
}

class _SwapResponseScreenState extends State<SwapResponseScreen> {
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final accepted = await FirebaseFirestore.instance
          .collection('swap_requests')
          .where('from_user_id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final rejected = await FirebaseFirestore.instance
          .collection('swap_requests')
          .where('from_user_id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'rejected')
          .get();

      final allDocs = [...accepted.docs, ...rejected.docs];
      allDocs.sort((a, b) {
        final aTime = (a.data()['created_at'] as dynamic).toDate();
        final bTime = (b.data()['created_at'] as dynamic).toDate();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _responses = allDocs.map((d) => d.data() as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ответ на замену')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
          ? const Center(child: Text('Нет ответов', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _responses.length,
        itemBuilder: (context, index) {
          final data = _responses[index];
          final status = data['status'] as String? ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text('📅 Дата: ${data['date']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['new_date'] != null && (data['new_date'] as String).isNotEmpty)
                    Text('🔄 Новая дата: ${data['new_date']}'),
                  Text('Решение: ${status == 'accepted' ? '✅ Принято' : '❌ Отклонено'}'),
                ],
              ),
              trailing: Icon(
                status == 'accepted' ? Icons.check_circle : Icons.cancel,
                color: status == 'accepted' ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}