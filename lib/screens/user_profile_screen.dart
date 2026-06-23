import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  int _photoVersion = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appUser = authProvider.appUser;

    if (appUser == null) {
      return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    }

    final hasPhoto = appUser.photoUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                InkWell(
                  onTap: () => _pickImage(authProvider),
                  borderRadius: BorderRadius.circular(60),
                  child: CircleAvatar(
                    key: ValueKey('photo_$_photoVersion'),
                    radius: 60,
                    backgroundColor: _getRoleColor(appUser.role),
                    backgroundImage: hasPhoto ? NetworkImage(appUser.photoUrl) : null,
                    child: !hasPhoto
                        ? Text(
                      _getInitials(appUser.fullName),
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                ),
                InkWell(
                  onTap: hasPhoto
                      ? () => _deletePhoto(authProvider)
                      : () => _pickImage(authProvider),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: hasPhoto ? Colors.red : Colors.blue,
                    child: Icon(
                      hasPhoto ? Icons.delete : Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 8),
            Text(
              hasPhoto ? 'Нажмите на фото, чтобы изменить' : 'Нажмите на фото, чтобы добавить',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(appUser.role).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleTitle(appUser.role),
                style: TextStyle(color: _getRoleColor(appUser.role), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, 'ФИО', appUser.fullName.isNotEmpty ? appUser.fullName : 'Не указано'),
                    const Divider(),
                    _buildInfoRow(Icons.email, 'Email', appUser.email),
                    const Divider(),
                    _buildInfoRow(Icons.shield, 'Роль', _getRoleTitle(appUser.role)),
                    const Divider(),
                    _buildInfoRow(Icons.work, 'Текущая категория', '${appUser.category}'),
                    const Divider(),
                    _buildInfoRow(Icons.list, 'Все категории', appUser.categories.join(', ')),
                    const Divider(),
                    _buildInfoRow(Icons.fingerprint, 'UID', appUser.uid.length > 16 ? '${appUser.uid.substring(0, 16)}...' : appUser.uid),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(AuthProvider authProvider) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (picked == null) return;

      setState(() => _isLoading = true);

      String photoUrl;

      if (kIsWeb) {
        // Веб: читаем байты
        final bytes = await picked.readAsBytes();
        photoUrl = await _cloudinaryService.uploadPhoto(bytes: bytes);
      } else {
        // Мобильные: файл
        final file = File(picked.path);
        photoUrl = await _cloudinaryService.uploadPhoto(file: file);
      }

      await authProvider.updatePhotoUrl(photoUrl);

      setState(() {
        _photoVersion++;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Фото обновлено')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка загрузки фото: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text('Фото профиля будет удалено.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    await authProvider.removePhotoUrl();

    setState(() {
      _photoVersion++;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Фото удалено')),
      );
    }
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.boss: return Colors.teal;
      case AppRole.developer: return Colors.red;
      case AppRole.user: return Colors.blue;
    }
  }

  String _getRoleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
      case AppRole.boss: return 'Начальник';
      case AppRole.admin: return 'Администратор';
      case AppRole.developer: return 'Разработчик';
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}