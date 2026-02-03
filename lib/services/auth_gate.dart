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
          return const HomeScreen();
        }

        // NO LOGUEADO
        return const LoginScreen();
      },
    );
  }

  // SIGN OUT METHOD
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Register Method
  Future<UserCredential> register(
      {required String email, 
      required String password,
      required String name,
      required String phone}) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
