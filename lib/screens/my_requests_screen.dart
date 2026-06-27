import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('swap_requests')
          .where('to_user_id', isEqualTo: currentUser.uid)
          .get();

      final docs = snapshot.docs.map((d) {
        final data = d.data();
        data['doc_id'] = d.id;
        return data;
      }).toList();

      docs.sort((a, b) {
        final aTime = (a['created_at'] as dynamic).toDate();
        final bTime = (b['created_at'] as dynamic).toDate();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _requests = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptWithDate(String docId, Map<String, dynamic> data) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null) return;

    final newDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('swap_requests').doc(docId).update({
      'status': 'accepted',
      'new_date': newDate,
    });

    final fromUserId = data['from_user_id'] as String;
    final scheduleDoc = await FirebaseFirestore.instance.collection('schedule').doc(newDate).get();
    List<String> userIds = [];
    if (scheduleDoc.exists) {
      userIds = List<String>.from(scheduleDoc.data()!['user_ids'] ?? []);
    }
    if (!userIds.contains(fromUserId)) userIds.add(fromUserId);
    await FirebaseFirestore.instance.collection('schedule').doc(newDate).set({
      'date': newDate,
      'user_ids': userIds,
    });

    final oldDate = data['date'] as String;
    final oldDoc = await FirebaseFirestore.instance.collection('schedule').doc(oldDate).get();
    if (oldDoc.exists) {
      final oldIds = List<String>.from(oldDoc.data()!['user_ids'] ?? []);
      oldIds.remove(fromUserId);
      if (oldIds.isEmpty) {
        await FirebaseFirestore.instance.collection('schedule').doc(oldDate).delete();
      } else {
        await FirebaseFirestore.instance.collection('schedule').doc(oldDate).update({'user_ids': oldIds});
      }
    }

    await _addSwapNote(newDate, data);
    await _addSwapNote(oldDate, data);

    _loadRequests();
  }

  Future<void> _addSwapNote(String dateStr, Map<String, dynamic> data) async {
    final fromUserName = data['from_user_name'] as String? ?? '';
    final toUserName = data['to_user_name'] as String? ?? '';

    final docId = '${dateStr}_swap';
    final noteDoc = await FirebaseFirestore.instance.collection('day_notes').doc(docId).get();
    String existingNote = '';

    if (noteDoc.exists && noteDoc.data() != null) {
      existingNote = noteDoc.data()!['note'] as String? ?? '';
    }

    final swapNote = '🔄 Замена: $fromUserName ↔ $toUserName';

    if (existingNote.contains(swapNote)) return;

    final updatedNote = existingNote.isNotEmpty
        ? '$existingNote\n$swapNote'
        : swapNote;

    await FirebaseFirestore.instance.collection('day_notes').doc(docId).set({
      'date': dateStr,
      'note': updatedNote,
    });
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('swap_requests').doc(docId).update({'status': status});
    _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Запросы на замену')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(child: Text('Нет запросов', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final data = _requests[index];
          final status = data['status'] as String? ?? 'pending';
          final docId = data['doc_id'] as String;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(data['from_user_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('📅 Дата смены: ${data['date']}'),
                  Text('📂 Категория замены: ${data['to_category']}'),
                  if (status != 'pending' && (data['new_date'] as String?)?.isNotEmpty == true)
                    Text('🔄 Новая дата: ${data['new_date']}'),
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
                      status == 'pending' ? '⏳ Ожидает' : status == 'accepted' ? '✅ Принято' : '❌ Отклонено',
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
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            swapRequestId: docId,
                            chatTitle: 'Чат: ${data['from_user_name']}',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _acceptWithDate(docId, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _updateStatus(docId, 'rejected'),
                  ),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            swapRequestId: docId,
                            chatTitle: 'Чат: ${data['from_user_name']}',
                          ),
                        ),
                      );
                    },
                  ),
                  Icon(
                    status == 'accepted' ? Icons.check_circle : Icons.cancel,
                    color: status == 'accepted' ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}