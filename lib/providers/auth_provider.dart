import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  AppUser? _appUser;
  String? _errorMessage;
  bool _isLoading = false;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null && _appUser != null;

  AppRole get currentRole => _appUser?.role ?? AppRole.user;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadAppUser(user.uid);
      } else {
        _appUser = null;
        notifyListeners();
      }
    });
  }

  /// Загружает данные пользователя из Firestore
  Future<void> _loadAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _appUser = AppUser.fromFirestore(uid, doc.data()!);
      } else {
        _appUser = AppUser(
          uid: uid,
          email: _firebaseUser?.email ?? '',
          fullName: '',
          role: AppRole.user,
        );
      }
    } catch (e) {
      _appUser = AppUser(
        uid: uid,
        email: _firebaseUser?.email ?? '',
        fullName: '',
        role: AppRole.user,
      );
    }
    notifyListeners();
  }

  /// Регистрация — теперь с ФИО
  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Создаём запись в Firestore с ФИО и ролью user по умолчанию
      final newUser = AppUser(
        uid: credential.user!.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        role: AppRole.user,
      );
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toFirestore());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Вход
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Выход
  Future<void> logout() async {
    await _auth.signOut();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Почта уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'weak-password':
        return 'Пароль слишком слабый (минимум 6 символов)';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      default:
        return 'Ошибка: $code';
    }
  }
}