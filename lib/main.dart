import 'package:flutter/material.dart';
import 'package:soka/Screen/home_page.dart';
import 'package:soka/Screen/login_screen.dart';

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
      initialRoute: 'homePage',
      routes: {
        'homePage': (context) => const HomePage(),
        'login': (context) => const LoginScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Hello, World!'),
        ),
      ),
    );
  }
}

