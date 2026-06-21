import 'package:flutter/material.dart';
import '../models/app_user.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;
  final Color? defaultColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.defaultColor,
  });

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return Colors.orange;
      case AppRole.developer:
        return Colors.red;
      case AppRole.user:
        return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoUrl.isNotEmpty;
    final bgColor = defaultColor ?? _getRoleColor(user.role);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: hasPhoto ? NetworkImage(user.photoUrl) : null,
      child: !hasPhoto
          ? Text(
        _getInitials(user.fullName),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      )
          : null,
    );
  }
}