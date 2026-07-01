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
  String? _resetMessage;
  bool _isLoading = false;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  String? get resetMessage => _resetMessage;
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
          category: 4,
          categories: const [4],
          photoUrl: '',
        );
      }
    } catch (e) {
      _appUser = AppUser(
        uid: uid,
        email: _firebaseUser?.email ?? '',
        fullName: '',
        role: AppRole.user,
        category: 4,
        categories: const [4],
        photoUrl: '',
      );
    }
    notifyListeners();
  }

  /// Обновить photoUrl в Firestore
  Future<void> updatePhotoUrl(String photoUrl) async {
    if (_firebaseUser == null || _appUser == null) return;
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'photo_url': photoUrl,
    });
    _appUser = _appUser!.copyWith(photoUrl: photoUrl);
    notifyListeners();
  }

  /// Удалить photoUrl из Firestore
  Future<void> removePhotoUrl() async {
    if (_firebaseUser == null || _appUser == null) return;
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'photo_url': '',
    });
    _appUser = _appUser!.copyWith(photoUrl: '');
    notifyListeners();
  }

  /// Регистрация с несколькими категориями
  Future<bool> register(String email, String password, String fullName, int category, List<int> categories) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = AppUser(
        uid: credential.user!.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        role: AppRole.user,
        category: category,
        categories: categories,
        photoUrl: '',
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

  /// Сброс пароля
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _resetMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _resetMessage = 'Ссылка для сброса пароля отправлена на $email. Проверьте почту.';
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Очистить сообщения об ошибках и уведомления
  void clearError() {
    _errorMessage = null;
    _resetMessage = null;
    notifyListeners();
  }

  /// Проверить, принято ли пользовательское соглашение
  Future<bool> isPrivacyPolicyAccepted() async {
    if (_firebaseUser == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(_firebaseUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['privacy_accepted'] as bool? ?? false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Принять пользовательское соглашение
  Future<void> acceptPrivacyPolicy() async {
    if (_firebaseUser == null) return;
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'privacy_accepted': true,
    });
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