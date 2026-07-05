import 'package:flutter/material.dart';

import '../services/version_service.dart';

class CalendarSettingsScreen extends StatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  State<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen> {
  bool _startWeekOnMonday = true;
  bool _showWeekNumbers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки календаря')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Отображение', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Начало недели с понедельника'),
            subtitle: const Text('Иначе с воскресенья'),
            value: _startWeekOnMonday,
            onChanged: (v) => setState(() => _startWeekOnMonday = v),
          ),
          SwitchListTile(
            title: const Text('Показывать номера недель'),
            subtitle: const Text('Номер недели слева от строки'),
            value: _showWeekNumbers,
            onChanged: (v) => setState(() => _showWeekNumbers = v),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Резервное копирование', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Экспорт данных'),
            subtitle: const Text('Сохранить все смены в файл'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция в разработке')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Импорт данных'),
            subtitle: const Text('Восстановить из файла'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция в разработке')),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('О приложении', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Версия'),
            subtitle: Text('Версия ${VersionService.versionString}',),
          ),
        ],
      ),
    );
  }
}