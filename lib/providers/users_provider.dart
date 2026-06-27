import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class UsersProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AppUser> _users = [];
  bool _isLoading = false;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;

  UsersProvider() {
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').orderBy('full_name').get();
      _users = snapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Ошибка загрузки пользователей: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Получить пользователя по uid
  Future<AppUser?> getUserById(String uid) async {
    // Сначала ищем в кэше
    try {
      return _users.firstWhere((u) => u.uid == uid);
    } catch (e) {
      // Если нет в кэше — загружаем из Firestore
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromFirestore(uid, doc.data()!);
        }
      } catch (e) {
        print('Ошибка загрузки пользователя: $e');
      }
      return null;
    }
  }

  Future<void> refresh() => _loadUsers();
}