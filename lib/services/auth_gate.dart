import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui_auth;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:soka/screens/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String googleClientId =
      '506945347137-bt2cb9i8nfpvg2pne0qbbq7eabkc1085.apps.googleusercontent.com';

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

        // NO LOGUEADO → LOGIN UI
        return ui_auth.SignInScreen(
          providers: [
            ui_auth.EmailAuthProvider(),
            GoogleProvider(clientId: googleClientId),
          ],
        );
      },
    );
  }
}
