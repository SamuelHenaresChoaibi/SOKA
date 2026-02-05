import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Page'),
      ),
      body: Column(
        children: [
          const Text("Cuenta", textAlign: TextAlign.left,),
          Container(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Username"),
              subtitle: const Text("correo@gmail.com"),
              onTap: () {
                // Navigate to account settings page
              },
            ),
          ),
        ],
      )
    );
  }
}
