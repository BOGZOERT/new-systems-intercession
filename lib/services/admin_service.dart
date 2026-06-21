import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать пользователя без входа в его аккаунт
  Future<String> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required int category,
    required List<int> categories,
  }) async {
    // Сохраняем текущего пользователя
    final currentUser = _auth.currentUser;

    // Создаём нового пользователя
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final newUid = credential.user!.uid;

    // Сохраняем данные в Firestore
    await _firestore.collection('users').doc(newUid).set({
      'email': email.trim(),
      'full_name': fullName.trim(),
      'role': role,
      'category': category,
      'categories': categories,
    });

    // Выходим из нового аккаунта
    await _auth.signOut();

    // Входим обратно в аккаунт админа
    if (currentUser != null) {
      // Переподключаемся — нужно заново войти
      // Но токен текущего пользователя уже недействителен после signOut
      // Поэтому нужно сохранить токен или использовать Firebase Admin SDK
      // Для клиентского приложения лучше создать пользователя через Cloud Function
    }

    return newUid;
  }

  /// Создать пользователя БЕЗ смены текущего аккаунта
  /// Используем второй экземпляр FirebaseAuth
  Future<String> createUserWithoutLogin({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required int category,
    required List<int> categories,
  }) async {
    // Создаём второго пользователя через Firebase REST API
    // или используем вторичный app
    final secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final newUid = credential.user!.uid;

    // Сохраняем данные
    await _firestore.collection('users').doc(newUid).set({
      'email': email.trim(),
      'full_name': fullName.trim(),
      'role': role,
      'category': category,
      'categories': categories,
    });

    // Выходим из вторичного app
    await secondaryAuth.signOut();
    await secondaryApp.delete();

    return newUid;
  }
}