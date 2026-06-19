import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _photoFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  int _photoVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    if (kIsWeb) return; // Веб: показываем инициалы, фото не сохраняем

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_photo.jpg');
      if (await file.exists()) {
        setState(() {
          _photoFile = file;
          _photoVersion++;
        });
      }
    } catch (e) {
      print('Ошибка загрузки фото: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);

      if (picked != null) {
        setState(() => _isLoading = true);

        if (kIsWeb) {
          // Веб: читаем байты сразу
          final bytes = await picked.readAsBytes();
          setState(() {
            _webImage = bytes;
            _photoVersion++;
            _isLoading = false;
          });
        } else {
          // Мобильные: сохраняем в файл
          final dir = await getApplicationDocumentsDirectory();
          final oldFile = File('${dir.path}/user_photo.jpg');
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          await Future.delayed(const Duration(milliseconds: 100));
          await File(picked.path).copy(oldFile.path);

          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();

          setState(() {
            _photoFile = File(oldFile.path);
            _photoVersion++;
            _isLoading = false;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Фото обновлено')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Ошибка выбора фото: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
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

    try {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/user_photo.jpg');
        if (await file.exists()) {
          await file.delete();
        }
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      }

      setState(() {
        _photoFile = null;
        _webImage = null;
        _photoVersion++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Фото удалено')),
        );
      }
    } catch (e) {
      print('Ошибка удаления фото: $e');
    }
  }

  /// Есть ли фото (веб или мобильное)
  bool get _hasPhoto => _photoFile != null || _webImage != null;

  /// Провайдер изображения для CircleAvatar
  ImageProvider? get _backgroundImage {
    if (kIsWeb && _webImage != null) {
      return MemoryImage(_webImage!);
    }
    if (!kIsWeb && _photoFile != null) {
      return FileImage(_photoFile!);
    }
    return null;
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin: return Colors.orange;
      case AppRole.developer: return Colors.red;
      case AppRole.user: return Colors.blue;
    }
  }

  String _getRoleTitle(AppRole role) {
    switch (role) {
      case AppRole.user: return 'Пользователь';
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

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AuthProvider>().appUser;

    if (appUser == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Фото
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(60),
                  child: CircleAvatar(
                    key: ValueKey('photo_$_photoVersion'),
                    radius: 60,
                    backgroundColor: _getRoleColor(appUser.role),
                    backgroundImage: _backgroundImage,
                    child: !_hasPhoto
                        ? Text(
                      _getInitials(appUser.fullName),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
                InkWell(
                  onTap: _hasPhoto ? _deletePhoto : _pickImage,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: _hasPhoto ? Colors.red : Colors.blue,
                    child: Icon(
                      _hasPhoto ? Icons.delete : Icons.camera_alt,
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
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              _hasPhoto ? 'Нажмите на фото, чтобы изменить' : 'Нажмите на фото, чтобы добавить',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Роль
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(appUser.role).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleTitle(appUser.role),
                style: TextStyle(
                  color: _getRoleColor(appUser.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Карточка с данными
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