import 'package:flutter/material.dart';

class OnlineStatus extends StatelessWidget {
  final DateTime? lastActive;

  const OnlineStatus({super.key, this.lastActive});

  bool get isOnline {
    if (lastActive == null) return false;
    final diff = DateTime.now().difference(lastActive!);
    return diff.inMinutes < 5;
  }

  String get statusText {
    if (lastActive == null) return 'Нет данных';
    if (isOnline) return 'В сети';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 60) return 'Был(а) ${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return 'Был(а) ${diff.inHours} ч. назад';
    return 'Был(а) ${diff.inDays} дн. назад';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 11,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}