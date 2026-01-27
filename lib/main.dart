import 'package:flutter/material.dart';
import 'package:soka/core/app_colors.dart';
import 'package:soka/screens/home_page.dart';
import 'package:soka/screens/login_screen.dart';
import 'package:soka/screens/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOKA',
      initialRoute: 'login',
      routes: {
        'homePage': (context) => const HomePage(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
      },
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.secondary,
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color.fromARGB(178, 255, 255, 255),
          selectionColor: AppColors.accent,
          selectionHandleColor: AppColors.accent,
        ),
      ),
    );
  }
}

