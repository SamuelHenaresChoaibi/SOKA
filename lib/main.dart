import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:soka/firebase_options.dart';

import 'package:soka/screens/home_page.dart';
import 'package:soka/screens/login_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(AppState());
}

class AppState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SokaService())],
      child: MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ligthTheme,
      title: 'SOKA',
      initialRoute: 'homePage',
      routes: {
        'homePage': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        // 'register': (context) => const RegisterScreen(),
        //'registerCompany': (context) => const RegisterCompanyScreen(),
        '/': (context) => const AuthGate(),
      },
    );
  }
}
