import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:new_systems_intercession/screens/user_profile_screen.dart';
import 'package:new_systems_intercession/screens/worker_profile_screen.dart';
import 'package:provider/provider.dart';
import '../models/worker_model.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/table_provider.dart';
import 'dev_screen.dart';
import 'add_user_screen.dart';
import 'calendar_screen.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.currentRole;
    tableProvider.setRoleFromAuth(role);

    return Scaffold(
      appBar: AppBar(
        title: Text('Таблица смен — ${_roleTitle(role)}'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        actions: [
          if (authProvider.appUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Chip(
                  avatar: CircleAvatar(
                    radius: 14,
                    backgroundColor: _getRoleColor(role),
                    child: Text(
                      _getInitials(authProvider.appUser!.fullName),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(
                    authProvider.appUser!.fullName.isNotEmpty
                        ? authProvider.appUser!.fullName
                        : authProvider.appUser!.email,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      endDrawer: (role == AppRole.admin || role == AppRole.developer)
          ? _buildDrawer(context, role)
          : null,
      body: RefreshIndicator(
        onRefresh: () => tableProvider.refresh(),
        child: _buildTable(context),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppRole role) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Настройки', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Настройка таблицы
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Настройка таблицы'),
            onTap: () {
              Navigator.pop(context);
              // Здесь можно открыть настройки колонок
            },
          ),

          // Добавить пользователя
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Добавить пользователя'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
            },
          ),

          const Divider(),

          // Календарь (внизу)
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: const Text('Календарь смен'),
            subtitle: const Text('Просмотр по дням'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final provider = context.watch<TableProvider>();
    final workers = provider.visibleWorkers;
    final role = context.watch<AuthProvider>().currentRole;

    if (provider.isLoading && workers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => provider.refresh(), child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (workers.isEmpty) {
      return const Center(child: Text('Нет данных', style: TextStyle(fontSize: 16)));
    }

    return DataTable2(
      columnSpacing: 10,
      horizontalMargin: 12,
      minWidth: 900,
      dataRowHeight: 56,
      headingRowColor: WidgetStatePropertyAll(Colors.grey.shade200),
      columns: [
        const DataColumn2(label: Text('Фамилия'), fixedWidth: 110),
        const DataColumn2(label: Text('Кат.'), numeric: true, size: ColumnSize.S),
        const DataColumn2(label: Text('Кол-во\nсмен'), numeric: true, size: ColumnSize.S),
        const DataColumn2(label: Text('Должен\nотдать'), numeric: true, size: ColumnSize.S),
        const DataColumn2(label: Text('Подраб.\n(часы)'), numeric: true, size: ColumnSize.S),
        const DataColumn2(label: Text('Отдал /\nНе выход'), size: ColumnSize.M),
        const DataColumn2(label: Text('Болеет /\nОтпуск'), size: ColumnSize.M),
        if (role != AppRole.user)
          const DataColumn2(label: Text(''), size: ColumnSize.S, fixedWidth: 50),
      ],
      rows: workers.map((w) => _buildRow(context, w, role)).toList(),
    );
  }

  DataRow _buildRow(BuildContext context, WorkerModel w, AppRole role) {
    return DataRow(cells: [
      DataCell(
        GestureDetector(
          onTap: () async {
            final updated = await Navigator.push<WorkerModel>(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerProfileScreen(worker: w),
              ),
            );
            if (updated != null) {
              context.read<TableProvider>().updateWorker(w.id, updated);
            }
          },
          child: Text(
            w.lastName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
      DataCell(Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getCategoryColor(w.category),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('${w.category}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      )),
      DataCell(Center(child: Text(w.totalShifts.toString()))),
      DataCell(Center(child: Text(w.mustGive.toString()))),
      DataCell(Center(child: Text(w.overtimeHours.toString()))),
      DataCell(_shiftStatusChip(w)),
      DataCell(_absenceChip(w)),
      if (role != AppRole.user)
        DataCell(IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _onEdit(context, w),
        )),
    ]);
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

  Widget _shiftStatusChip(WorkerModel w) {
    if (w.shiftGiven) {
      return const Chip(label: Text('Отдал'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white, fontSize: 12));
    } else {
      return const Chip(label: Text('Не выход'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white, fontSize: 12));
    }
  }

  Widget _absenceChip(WorkerModel w) {
    if (w.shiftGiven) return const Text('-', style: TextStyle(color: Colors.grey));
    switch (w.absenceReason) {
      case AbsenceReason.sick:
        return const Chip(label: Text('Болеет'), backgroundColor: Colors.red, labelStyle: TextStyle(color: Colors.white, fontSize: 12));
      case AbsenceReason.vacation:
        return const Chip(label: Text('Отпуск'), backgroundColor: Colors.blue, labelStyle: TextStyle(color: Colors.white, fontSize: 12));
      default:
        return const Text('-', style: TextStyle(color: Colors.grey));
    }
  }

  void _onEdit(BuildContext context, WorkerModel w) {
    final provider = context.read<TableProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool shiftGiven = w.shiftGiven;
        AbsenceReason? absence = w.absenceReason;
        int mustGive = w.mustGive;
        int category = w.category;
        final dropdownKey = GlobalKey<FormFieldState>();

        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Редактировать: ${w.lastName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Отдал смену'),
                  value: shiftGiven,
                  onChanged: (v) {
                    setDialogState(() {
                      shiftGiven = v;
                      if (v) absence = null;
                    });
                    if (v) dropdownKey.currentState?.reset();
                  },
                ),
                if (!shiftGiven) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AbsenceReason?>(
                    key: dropdownKey,
                    initialValue: absence,
                    decoration: const InputDecoration(labelText: 'Причина невыхода'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Без причины')),
                      DropdownMenuItem(value: AbsenceReason.sick, child: Text('Болеет')),
                      DropdownMenuItem(value: AbsenceReason.vacation, child: Text('Отпуск')),
                    ],
                    onChanged: (v) => setDialogState(() => absence = v),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Категория'),
                  items: [4, 5, 6, 7, 8]
                      .map((c) => DropdownMenuItem(value: c, child: Text('$c категория')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Должен отдать'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: mustGive.toString()),
                  onChanged: (v) => mustGive = int.tryParse(v) ?? 0,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: () {
                  provider.updateWorker(w.id, w.copyWith(
                    shiftGiven: shiftGiven,
                    clearAbsence: shiftGiven,
                    absenceReason: shiftGiven ? null : absence,
                    mustGive: mustGive,
                    category: category,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  String _roleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
      case AppRole.boss: return 'Начальник';
      case AppRole.admin: return 'Администратор';
      case AppRole.developer: return 'Разработчик';
    }
  }
  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.developer: return Colors.red;
      case AppRole.boss: return Colors.teal;
      case AppRole.user: return Colors.blue;
    }
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