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

  Future<void> refresh() => _loadUsers();
}