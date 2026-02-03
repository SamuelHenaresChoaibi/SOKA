import 'package:flutter/material.dart';
import 'package:soka/services/auth_gate.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
            //TODO: Implementar logout
            AuthGate().signOut();
            Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
        ),
      ),
      body: const Center(child: Text('SOKA')),
    );
  }
}
