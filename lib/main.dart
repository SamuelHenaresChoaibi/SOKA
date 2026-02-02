import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soka/firebase_options.dart';

import 'package:soka/screens/home_page.dart';
import 'package:soka/screens/login_screen.dart';
import 'package:soka/screens/register_client_screen.dart';
import 'package:soka/screens/register_company_screen.dart';
import 'package:soka/services/auth_gate.dart';
import 'package:soka/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ligthTheme,
      title: 'SOKA',
      home: const AuthGate(),
      routes: {
        'homePage': (context) => const HomePage(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'registerCompany': (context) => const RegisterCompanyScreen(),
      },
    );
  }
}
