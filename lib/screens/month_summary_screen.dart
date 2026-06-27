import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/month_summary.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../models/app_user.dart';
import 'month_payment_screen.dart';

class MonthSummaryScreen extends StatefulWidget {
  const MonthSummaryScreen({super.key});

  @override
  State<MonthSummaryScreen> createState() => _MonthSummaryScreenState();
}

class _MonthSummaryScreenState extends State<MonthSummaryScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  double _ratePerShift = 0;
  bool _isLoading = false;
  MonthSummary? _summary;
  final _rateController = TextEditingController();

  String get _monthStr =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    final docId = '${_monthStr}_${currentUser.uid}';
    final doc = await FirebaseFirestore.instance.collection('month_summaries').doc(docId).get();

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    int shiftCount = 0;
    final factEntries = <ShiftEntry>[];
    final paymentEntries = <ShiftEntry>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final scheduleDoc = await FirebaseFirestore.instance.collection('schedule').doc(dateStr).get();

      if (scheduleDoc.exists) {
        final data = scheduleDoc.data()!;
        final userIds = List<String>.from(data['user_ids'] ?? []);
        if (userIds.contains(currentUser.uid)) {
          shiftCount++;
        }
      }

      final swaps = await FirebaseFirestore.instance
          .collection('swap_requests')
          .where('status', isEqualTo: 'accepted')
          .where('new_date', isEqualTo: dateStr)
          .where('from_user_id', isEqualTo: currentUser.uid)
          .get();

      for (var swap in swaps.docs) {
        final swapData = swap.data();
        factEntries.add(ShiftEntry(
          replacedUser: swapData['to_user_name'] as String? ?? '',
          replacementUser: currentUser.fullName,
          count: 1,
          date: dateStr,
          type: 'fact',
        ));
      }
    }

    if (doc.exists) {
      final existing = MonthSummary.fromFirestore(docId, doc.data()!);
      final baseFactEntries = existing.factEntries.isNotEmpty ? existing.factEntries : factEntries;

      setState(() {
        _summary = existing.copyWith(
          totalShifts: shiftCount,
          factEntries: baseFactEntries,
        );
        _ratePerShift = existing.ratePerShift;
        _rateController.text = _ratePerShift > 0 ? _ratePerShift.toStringAsFixed(0) : '';
      });
    } else {
      setState(() {
        _summary = MonthSummary(
          id: docId,
          userId: currentUser.uid,
          month: _monthStr,
          totalShifts: shiftCount,
          factEntries: factEntries,
        );
        _ratePerShift = 0;
        _rateController.text = '';
      });
    }

    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('month_summaries')
        .where('month', isEqualTo: _monthStr)
        .get();

    for (var doc in paymentSnapshot.docs) {
      final data = doc.data();
      final rawEntries = data['payment_entries'];
      if (rawEntries is List) {
        for (var entry in rawEntries) {
          final e = entry is Map<String, dynamic> ? entry : Map<String, dynamic>.from(entry as Map);
          if (e['replaced_user_id'] == currentUser.uid) {
            paymentEntries.add(ShiftEntry(
              replacedUser: currentUser.fullName,
              replacementUser: e['replacement_user'] as String? ?? '',
              count: (e['count'] as num?)?.toInt() ?? 1,
              date: e['date'] as String? ?? '',
              type: 'payment',
            ));
          }
        }
      }
    }

    setState(() {
      _summary = _summary?.copyWith(paymentEntries: paymentEntries);
      _isLoading = false;
    });

    _calculateEarnings();
  }

  void _calculateEarnings() {
    if (_summary == null) return;
    setState(() {
      _summary = _summary!.copyWith(
        ratePerShift: _ratePerShift,
        totalEarnings: _ratePerShift * _summary!.totalShifts,
      );
    });
    _saveRate();
  }

  Future<void> _saveRate() async {
    final currentUser = context.read<AuthProvider>().appUser;
    if (currentUser == null || _summary == null) return;

    final docId = '${_monthStr}_${currentUser.uid}';
    final docRef = FirebaseFirestore.instance.collection('month_summaries').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'rate_per_shift': _ratePerShift,
        'total_earnings': _summary!.totalEarnings,
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadSummary();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadSummary();
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().appUser;
    final role = currentUser?.role ?? AppRole.user;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text('Итоги — ${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}'),
        actions: [
          if (role == AppRole.developer || role == AppRole.boss)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MonthPaymentScreen(month: _monthStr)),
                ).then((_) => _loadSummary());
              },
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text('Итоги выходов', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
          ? const Center(child: Text('Нет данных'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(
                  '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _statRow('Кол-во смен', '${_summary!.totalShifts}'),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Сумма за смену:'),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              suffixText: '₽',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            controller: _rateController,
                            onChanged: (v) {
                              _ratePerShift = double.tryParse(v) ?? 0;
                              _calculateEarnings();
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _statRow(
                      'Заработано за месяц',
                      '${_summary!.totalEarnings.toStringAsFixed(0)} ₽',
                      valueBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'По факту (кого заменил)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_summary!.factEntries.isEmpty)
              const Text('Нет записей', style: TextStyle(color: Colors.grey))
            else
              _buildEntriesTable(_summary!.factEntries),

            const SizedBox(height: 16),

            const Text(
              'По выплате (кто заменил вас)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_summary!.paymentEntries.isEmpty)
              const Text('Нет записей', style: TextStyle(color: Colors.grey))
            else
              _buildEntriesTable(_summary!.paymentEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesTable(List<ShiftEntry> entries) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Кого заменили', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Кто заменил', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Выходов', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Дата', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...entries.map(
              (e) => TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(e.replacedUser)),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.replacementUser)),
              Padding(padding: const EdgeInsets.all(8), child: Text('${e.count}')),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.date)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, {bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
