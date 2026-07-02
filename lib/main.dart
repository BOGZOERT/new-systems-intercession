import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/users_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/choice_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/privacy_policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Таблица смен',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.firebaseUser;

    if (user == null) {
      return const AuthScreen();
    }

    final appUser = authProvider.appUser;

    if (appUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<bool>(
      future: authProvider.isPrivacyPolicyAccepted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data != true) {
          return const PrivacyPolicyScreen(showAcceptButton: true);
        }

        if (appUser.organizationId.isNotEmpty) {
          return const CalendarScreen();
        }

        return const ChoiceScreen();
      },
    );
  }
}