import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:soka/screens/home_page.dart';
import 'package:soka/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // LOGUEADO
        if (snapshot.hasData) {
          return const HomePage();
        }

        // NO LOGUEADO
        return const LoginScreen();
      },
    );
  }
}
